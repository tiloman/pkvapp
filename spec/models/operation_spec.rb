require "rails_helper"

RSpec.describe Operation, :type => :model do
  describe "new operation" do
    let(:user) { FactoryBot.create(:user) }
    let(:person) { FactoryBot.create(:person, user_id: user.id) }
    let(:operation) { FactoryBot.create(:operation, person_id: person.id, bill_deadline: Time.now + 7.days)}

    it "has the properly state" do
      expect(operation.aasm_state).to eq('editing')
    end

    it 'has enqueued the reminder mail' do
      expect { Operation.create(person_id: person.id, title: 'Tight Deadline', bill_deadline: Time.now + 1.day)
      }.to have_enqueued_job.with("OperationsMailer", "deadline_reminder", "deliver_now", user.id)
    end
  end
end
