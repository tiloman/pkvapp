class OperationsMailer < ApplicationMailer
  default from: "no-reply@timolohmann.de"
  layout 'mailer'

  def deadline_reminder(operation_id)
    @operation = Operation.find(operation_id)
    @user = @operation.person.user

    mail(to: @user.email, subject: I18n.t('operations_mailer.deadline_reminder.subject'))
  end
end
