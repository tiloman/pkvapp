class SyncTodoist
  include Interactor
  include Rails.application.routes.url_helpers

  require 'todoist'

  def call
    @operation = context.operation
    @user = context.operation.user

    return unless @user.todoist_integration

    todoist_client
    @operation.todoist_item_id ? update_todoist_item : create_todoist_item
  end

  def todoist_client
    @client ||= Todoist::Client.create_client_by_token(@user.todoist_integration.token)
  end

  def create_todoist_item
    @item = @client.sync_items.add(content)
    @client.sync
    @operation.update(todoist_item_id: @item.id)
  end

  def update_todoist_item
    done = @operation.paid ? 1 : 0
    @item = @client.sync_items.update(
      { id: @operation.todoist_item_id }.merge(content))
    @client.sync
  end

  def description
    "**Status: #{@operation.aasm_state}** \nPerson: #{@operation.person.name} \nBetrag: #{@operation.value} Euro\n\n[Bei Abile bearbeiten](#{operation_url(@operation)})"
  end

  def content
    {
      content: "Rechnung fällig: #{@operation.title}",
      due: { string: (@operation.bill_deadline - @user.remind_days_before.days).strftime("%d.%m.%Y") },
      description: description
    }
  end
end
