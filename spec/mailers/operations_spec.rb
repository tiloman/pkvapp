require "rails_helper"

RSpec.describe OperationsMailer, :type => :mailer do
  describe "operations" do
    let(:operation) {Operation.create(name: 'Rechnung', value: 100)}
    let(:mail) { OperationsMailer.insurance_reminder() }

    it "renders the headers" do
      expect(mail.subject).to eq("Signup")
      expect(mail.to).to eq(["to@example.org"])
      expect(mail.from).to eq(["from@example.com"])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Hi")
    end
  end
end
