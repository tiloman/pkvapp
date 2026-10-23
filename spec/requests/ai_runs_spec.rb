require 'rails_helper'
require_relative '../interactors/ai_run_helpers'

RSpec.describe 'AiRuns', type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { FactoryBot.create(:user) }
  let!(:person) { Person.create!(name: 'Hanna', color: 'red', ratio: '50/50', user: user) }
  let(:other_user) { FactoryBot.create(:user, email: 'other@example.com') }
  let(:pdf) { fixture_file_upload(Rails.root.join('spec/fixtures/files/rechnung.pdf'), 'application/pdf') }

  before do
    # The webpack manifest is not built in the test environment.
    allow_any_instance_of(ActionView::Base).to receive(:javascript_pack_tag).and_return('')
    allow_any_instance_of(ActionView::Base).to receive(:stylesheet_pack_tag).and_return('')
    allow(SyncTodoist).to receive(:call)
  end

  context 'without a signed-in user' do
    it 'redirects to login' do
      get new_ai_run_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  context 'signed in' do
    before { sign_in user }

    describe 'GET /ai_runs/new' do
      it 'sends users without an AI integration to the integrations page' do
        get new_ai_run_path
        expect(response).to redirect_to(integrations_path)
      end

      it 'renders the upload form with consent for new users' do
        AiIntegration.create!(user: user, provider: 'claude', api_key: 'k')
        get new_ai_run_path
        expect(response).to be_successful
        expect(response.body).to include('Gesundheitsdaten')
      end

      it "does not expose other users' operations" do
        AiIntegration.create!(user: user, provider: 'claude', api_key: 'k')
        foreign = Operation.create!(title: 'Fremd', value: 1, person: Person.create!(name: 'X', color: 'red', ratio: '50/50', user: other_user))
        expect { get new_ai_run_path(operation_id: foreign.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    describe 'POST /ai_runs' do
      before { AiIntegration.create!(user: user, provider: 'claude', api_key: 'k') }

      it 'requires consent on first use' do
        expect { post ai_runs_path, params: { ai_run: { document: pdf }, provider: 'claude' } }
          .not_to change(AiRun, :count)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(user.reload.ai_consented?).to be(false)
      end

      it 'creates a run, stores consent and enqueues the extraction' do
        expect { post ai_runs_path, params: { ai_run: { document: pdf }, provider: 'claude', consent: '1' } }
          .to change(AiRun, :count).by(1).and have_enqueued_job(ExtractBillJob)
        run = AiRun.last
        expect(response).to redirect_to(ai_run_path(run))
        expect([run.user, run.provider, run.status]).to eq([user, 'claude', 'processing'])
        expect(user.reload.ai_consented?).to be(true)
      end

      it 'reads the bill of an existing operation' do
        user.update!(ai_consented_at: Time.current)
        operation = Operation.create!(title: 'Alt', value: 1, person: person)
        operation.bill.attach(io: StringIO.new('%PDF'), filename: 'b.pdf', content_type: 'application/pdf')

        post ai_runs_path, params: { operation_id: operation.id, provider: 'claude' }
        run = AiRun.last
        expect(run.operation).to eq(operation)
        expect(run.document.blob).to eq(operation.bill.blob)
      end

      it 'ignores a provider the user has not connected' do
        user.update!(ai_consented_at: Time.current)
        post ai_runs_path, params: { ai_run: { document: pdf }, provider: 'gemini' }
        expect(AiRun.last.provider).to eq('claude')
      end

      it 'rejects a missing document' do
        user.update!(ai_consented_at: Time.current)
        post ai_runs_path, params: { provider: 'claude' }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    describe 'GET /ai_runs/:id' do
      it 'shows a processing run with polling' do
        get ai_run_path(create_run(user, status: 'processing', output: {}))
        expect(response.body).to include('data-controller="poll"')
      end

      it 'shows the review form with prefilled values and confidence' do
        get ai_run_path(create_run(user))
        expect(response).to be_successful
        expect(response.body).to include('Dr. Müller Zahnarztpraxis: Professionelle Zahnreinigung')
        expect(response.body).to include('95 %')
        expect(response.body).to include('Beleg')
      end

      it 'shows the error of a failed run' do
        run = create_run(user, status: 'failed', output: {})
        run.update!(error_message: 'abgelehnt')
        get ai_run_path(run)
        expect(response.body).to include('abgelehnt')
      end

      it 'is not accessible for other users' do
        run = create_run(other_user)
        expect { get ai_run_path(run) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    describe 'PATCH /ai_runs/:id' do
      let(:params) { { operation: { title: 'Zahnarzt', value: '50', bill_deadline: 5.days.from_now.to_date, person_id: person.id } } }

      it 'creates the operation and redirects to it' do
        run = create_run(user)
        expect { patch ai_run_path(run), params: params }.to change(Operation, :count).by(1)
        expect(response).to redirect_to(operation_path(Operation.last))
        expect(run.reload).to be_accepted
      end

      it 're-renders the review with errors for invalid input' do
        run = create_run(user)
        patch ai_run_path(run), params: { operation: { title: '', person_id: person.id } }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(run.reload).to be_proposed
      end
    end

    describe 'POST reject / revert / retry' do
      it 'rejects but keeps the run for the audit trail' do
        run = create_run(user)
        post reject_ai_run_path(run)
        expect(run.reload).to be_rejected
        expect(response).to redirect_to(dashboard_path)
      end

      it 'reverts an accepted run' do
        run = create_run(user)
        patch ai_run_path(run), params: { operation: { title: 'Zahnarzt', value: '50', bill_deadline: 5.days.from_now.to_date, person_id: person.id } }
        expect { post revert_ai_run_path(run) }.to change(Operation, :count).by(-1)
        expect(run.reload).to be_reverted
      end

      it 'retries with a new run on the same document' do
        AiIntegration.create!(user: user, provider: 'claude', api_key: 'k')
        run = create_run(user)
        expect { post retry_ai_run_path(run), params: { provider: 'claude' } }
          .to change(AiRun, :count).by(1).and have_enqueued_job(ExtractBillJob)
        expect(run.reload).to be_rejected
        expect(AiRun.last.document.blob).to eq(run.document.blob)
      end
    end

    describe 'GET /ai_runs' do
      it 'lists the own runs only' do
        create_run(user)
        create_run(other_user)
        get ai_runs_path
        expect(response).to be_successful
        expect(response.body.scan('rechnung.pdf').size).to eq(1)
      end
    end

    describe 'dashboard and operation page' do
      before { AiIntegration.create!(user: user, provider: 'claude', api_key: 'k') }

      it 'shows pending suggestions on the dashboard' do
        create_run(user)
        get dashboard_path
        expect(response.body).to include('wartet auf Prüfung')
      end

      it 'links the accepted run from the operation' do
        run = create_run(user)
        patch ai_run_path(run), params: { operation: { title: 'Zahnarzt', value: '50', person_id: person.id, bill_deadline: 2.days.from_now.to_date } }
        get operation_path(Operation.last)
        expect(response.body).to include('Aus Rechnung per KI übernommen')
        expect(response.body).to include('Aus Rechnung ausfüllen')
      end
    end
  end
end
