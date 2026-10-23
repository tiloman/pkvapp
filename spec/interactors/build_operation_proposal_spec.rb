require 'rails_helper'
require_relative 'ai_run_helpers'

RSpec.describe BuildOperationProposal do
  let(:user) { FactoryBot.create(:user) }
  let!(:hanna) { Person.create!(name: 'Hanna', color: 'red', ratio: '50/50', user: user) }

  def propose(output = bill_output)
    described_class.call(ai_run: create_run(user, output: output))
  end

  it 'builds operation attributes from the extraction' do
    attrs = propose.attributes
    expect(attrs[:title]).to eq('Dr. Müller Zahnarztpraxis: Professionelle Zahnreinigung')
    expect(attrs[:value]).to eq(123.46)
    expect(attrs[:billing_date].to_date).to eq(Date.new(2026, 10, 1))
    expect(attrs[:bill_deadline].to_date).to eq(Date.new(2026, 10, 31))
    expect(attrs[:person_id]).to eq(hanna.id)
  end

  it 'prefers an explicit due date over payment terms' do
    attrs = propose(bill_output('due_date' => field('2026-10-15'))).attributes
    expect(attrs[:bill_deadline].to_date).to eq(Date.new(2026, 10, 15))
  end

  it 'leaves out values it cannot determine' do
    attrs = propose(bill_output('payment_terms_days' => field(nil), 'total_amount' => field(-5),
                                'invoice_date' => field('kein Datum'))).attributes
    expect(attrs.keys).to contain_exactly(:title, :person_id)
  end

  it 'truncates long titles to the validation limit' do
    attrs = propose(bill_output('summary' => field('x' * 300))).attributes
    expect(attrs[:title].length).to eq(100)
  end

  describe 'person matching' do
    it 'matches "Nachname, Vorname" and ignores titles' do
      attrs = propose(bill_output('patient_name' => field('Frau Lohmann, Hanna'))).attributes
      expect(attrs[:person_id]).to eq(hanna.id)
    end

    it 'prefers an exact match over a partial one' do
      full = Person.create!(name: 'Hanna Lohmann', color: 'blue', ratio: '50/50', user: user)
      expect(propose.attributes[:person_id]).to eq(full.id)
    end

    it 'leaves the person empty when ambiguous' do
      Person.create!(name: 'Lohmann', color: 'blue', ratio: '50/50', user: user)
      expect(propose.attributes).not_to have_key(:person_id)
    end

    it 'leaves the person empty when nobody matches' do
      expect(propose(bill_output('patient_name' => field('Max Mustermann'))).attributes).not_to have_key(:person_id)
    end

    it 'never matches people of other users' do
      other = FactoryBot.create(:user, email: 'other@example.com')
      Person.create!(name: 'Max', color: 'red', ratio: '50/50', user: other)
      expect(propose(bill_output('patient_name' => field('Max'))).attributes).not_to have_key(:person_id)
    end
  end

  describe 'warnings' do
    it 'flags reminders and non-bills' do
      expect(propose(bill_output('document_type' => field('reminder'))).warnings.join).to include('Mahnung')
      expect(propose(bill_output('document_type' => field('other'))).warnings.join).to include('nicht als Rechnung')
    end

    it 'lists low-confidence fields' do
      warnings = propose(bill_output('total_amount' => field(10, 0.4))).warnings
      expect(warnings.join).to include('total_amount')
    end

    it 'has no warnings for a clean bill' do
      expect(propose.warnings).to be_empty
    end
  end
end
