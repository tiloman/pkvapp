# Preview all emails at http://localhost:3000/rails/mailers/operations_mailer
class OperationsMailerPreview < ActionMailer::Preview
  def deadline_reminder
    operation = Operation.first
    OperationsMailer.deadline_reminder(operation.id)
  end
end
