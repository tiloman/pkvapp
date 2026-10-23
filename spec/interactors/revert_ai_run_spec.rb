require 'rails_helper'
require_relative 'ai_run_helpers'

RSpec.describe RevertAiRun do
  let(:user) { FactoryBot.create(:user) }
  let!(:person) { Person.create!(name: 'Hanna', color: 'red', ratio: '50/50', user: user) }
  let(:attributes) { { title: 'Zahnarzt', value: 99.5, bill_deadline: '2026-10-31', person_id: person.id } }

  before { allow(SyncTodoist).to receive(:call) }

  def accept(run)
    ApplyAiRun.call(ai_run: run, attributes: attributes).operation
  end

  it 'deletes an untouched operation created by the run' do
    run = create_run(user)
    accept(run)

    expect(described_class.call(ai_run: run.reload)).to be_a_success
    expect(Operation.count).to eq(0)
    expect(run.reload).to be_reverted
    expect(run.operation).to be_nil
    expect(run.document).to be_attached
  end

  it 'keeps a created operation that changed since' do
    run = create_run(user)
    operation = accept(run)
    operation.update_columns(updated_at: 1.hour.from_now)

    expect(described_class.call(ai_run: run.reload)).to be_a_failure
    expect(Operation.count).to eq(1)
    expect(run.reload).to be_accepted
  end

  it 'restores changed fields of an updated operation' do
    operation = Operation.create!(title: 'Alt', value: 1, person: person)
    run = create_run(user, operation: operation)
    accept(run)

    result = described_class.call(ai_run: run.reload)
    expect(result).to be_a_success
    expect(operation.reload.title).to eq('Alt')
    expect(operation.value).to eq(1)
    expect(run.reload).to be_reverted
  end

  it 'skips fields the user changed afterwards' do
    operation = Operation.create!(title: 'Alt', value: 1, person: person)
    run = create_run(user, operation: operation)
    accept(run)
    operation.reload.update!(title: 'Von Hand')

    result = described_class.call(ai_run: run.reload)
    expect(operation.reload.title).to eq('Von Hand')
    expect(operation.value).to eq(1)
    expect(result.skipped).to eq(['title'])
  end

  it 'only reverts accepted runs' do
    expect(described_class.call(ai_run: create_run(user))).to be_a_failure
  end
end
