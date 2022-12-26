class OperationMailer < ApplicationMailer
  default from: "from@example.com"
  layout 'mailer'

  def insurance_reminder(operation_id)
    @operation = Operation.find(operation_id)
    @user = @operation.user

    mail(to: @user.email, subject: 'Bald fällig')
  end
end
