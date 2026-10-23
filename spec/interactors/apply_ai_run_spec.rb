require 'rails_helper'
require_relative 'ai_run_helpers'

RSpec.describe ApplyAiRun do
  let(:user) { FactoryBot.create(:user) }
  let!(:person) { Person.create!(name: 'Hanna', color: 'red', ratio: '50/50', user: user) }
  let(:attributes) { { title: 'Zahnarzt', value: 99.5, bill_deadline: '2026-10-31', person_id: person.id } }

  before { allow(SyncTodoist).to receive(:call) }

  it 'creates the operation, attaches the document and records the run' do
    run = create_run(user)
    result = described_class.call(ai_run: run, attributes: attributes)

    expect(result).to be_a_success
    operation = result.operation
    expect(operation).to be_persisted
    expect(operation.bill).to be_attached
    expect(operation.bill.blob).to eq(run.document.blob)
    run.reload
    expect(run).to be_accepted
    expect(run.operation).to eq(operation)
    expect(run.decided_at).to be_present
    expect(run.applied_changes['_created']).to be(true)
    expect(run.applied_changes['title']).to eq([nil, 'Zahnarzt'])
    expect(SyncTodoist).to have_received(:call).with(operation: operation)
  end

  it 'ignores attributes outside the whitelist' do
    run = create_run(user)
    result = described_class.call(ai_run: run, attributes: attributes.merge(paid: true, insurance_paid: true))
    expect(result.operation.paid).to be(false)
    expect(result.operation.insurance_paid).to be(false)
  end

  it 'accepts multiparameter dates from date_select inputs' do
    run = create_run(user)
    result = described_class.call(
      ai_run: run,
      attributes: attributes.except(:bill_deadline).merge('bill_deadline(1i)' => '2026', 'bill_deadline(2i)' => '11',
                                                           'bill_deadline(3i)' => '5')
    )
    expect(result.operation.bill_deadline.to_date).to eq(Date.new(2026, 11, 5))
  end

  it 'rejects people of another account' do
    other = FactoryBot.create(:user, email: 'other@example.com')
    foreign = Person.create!(name: 'Max', color: 'red', ratio: '50/50', user: other)
    run = create_run(user)

    result = described_class.call(ai_run: run, attributes: attributes.merge(person_id: foreign.id))
    expect(result).to be_a_failure
    expect(run.reload).to be_proposed
    expect(Operation.count).to eq(0)
  end

  it 'requires value and deadline so the operation pages can render' do
    run = create_run(user)
    result = described_class.call(ai_run: run, attributes: attributes.except(:value, :bill_deadline))
    expect(result).to be_a_failure
    expect(result.operation.errors.attribute_names).to include(:value, :bill_deadline)
    expect(Operation.count).to eq(0)
    expect(run.reload).to be_proposed
  end

  it 'keeps the run proposed when the operation is invalid' do
    run = create_run(user)
    result = described_class.call(ai_run: run, attributes: attributes.merge(title: ''))
    expect(result).to be_a_failure
    expect(result.error).to be_present
    expect(run.reload).to be_proposed
    expect(Operation.count).to eq(0)
  end

  it 'refuses to apply a run twice' do
    run = create_run(user)
    described_class.call(ai_run: run, attributes: attributes)
    expect(described_class.call(ai_run: run.reload, attributes: attributes)).to be_a_failure
    expect(Operation.count).to eq(1)
  end

  it 'updates an existing operation and keeps its bill' do
    operation = Operation.create!(title: 'Alt', value: 1, person: person)
    operation.bill.attach(io: StringIO.new('old'), filename: 'old.pdf', content_type: 'application/pdf')
    run = create_run(user, operation: operation)

    described_class.call(ai_run: run, attributes: attributes)
    operation.reload
    expect(operation.title).to eq('Zahnarzt')
    expect(operation.bill.download).to eq('old')
    expect(run.reload.applied_changes['title']).to eq(%w[Alt Zahnarzt])
    expect(run.applied_changes).not_to have_key('_created')
  end
end
