require 'rails_helper'

RSpec.describe SyncTodoist do
  let(:user) { FactoryBot.create(:user) }
  let(:person) { user.people.first || Person.create!(name: 'Hanna', color: 'red', ratio: '50/50', user: user) }
  let(:operation) { Operation.create!(title: 'Zahnarzt', value: 10, person: person) }

  it 'skips the sync when the operation has no deadline' do
    TodoistIntegration.create!(user_id: user.id, token: 'x', project_id: '1')
    expect(TodoistClient).not_to receive(:new)
    expect(described_class.call(operation: operation)).to be_a_success
  end
end
