class SyncTodoist
  include Interactor
  include Rails.application.routes.url_helpers

  def call
    @operation = context.operation
    @user = context.operation.user

    return unless @user.todoist_integration

    @client = TodoistClient.new(@user.todoist_integration.token)
    @operation.todoist_item_id ? update_todoist_item : create_todoist_item
  rescue Faraday::TimeoutError, Faraday::ConnectionFailed => e
    Rails.logger.warn("Todoist sync timeout: #{e.message}")
    context.fail!(error: "Todoist ist derzeit nicht erreichbar.")
  end

  private

  def create_todoist_item
    result = @client.create_task(**task_params)
    @operation.update(todoist_item_id: result["id"])
  end

  def update_todoist_item
    @client.update_task(@operation.todoist_item_id, **task_params)
  end

  def task_params
    due = (@operation.bill_deadline - @user.remind_days_before.days).strftime("%Y-%m-%d")
    {
      content: "Rechnung fällig: #{@operation.title}",
      description: description,
      project_id: @user.todoist_integration.project_id,
      due_date: due
    }
  end

  def description
    "**Status: #{@operation.aasm_state}** \nPerson: #{@operation.person.name} \nBetrag: #{@operation.value} Euro\n\n[Bei Abile bearbeiten](#{operation_url(@operation)})"
  end
end
