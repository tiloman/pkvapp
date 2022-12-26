require "rails_helper"

RSpec.describe OperationsMailer, :type => :mailer do
  describe "operations" do
    let!(:user) { FactoryBot.create(:user) }
    let!(:person) { FactoryBot.create(:person, user_id: user.id) }
    let!(:operation) { FactoryBot.create(:operation, person_id: person.id, bill_deadline: Time.now + 7.days)}
    let!(:mail) { OperationsMailer.deadline_reminder(operation.id) }

    it "renders deadline_reminder mail" do
      expect(mail.subject).to eq(I18n.t('operations_mailer.deadline_reminder.subject'))
      expect(mail.to).to eq([user.email])
      expect(mail.from).to eq(["no-reply@timolohmann.de"])
      expect(mail.body.encoded).to match("Hi #{user.first_name}")
      expect(mail.body.encoded).to match(I18n.l(operation.bill_deadline, :format => :short))
    end
  end
end
