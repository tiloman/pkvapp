class IntegrationsController < ApplicationController
  before_action :authenticate_user!

  def index
    @todoist_integration = current_user.todoist_integration
    get_todoist_project_name
  end

  def new
  end

  def create
  end

  def edit
  end

  def update
  end

  def destroy

  end

  private

  def get_todoist_project_name
    return unless @todoist_integration

    client = Todoist::Client.create_client_by_token(@todoist_integration.token)
    collection = client.sync_projects.collection
    pid = @todoist_integration.project_id
    project = collection[pid] || collection[pid.to_s] || collection[pid.to_i]
    @project_name = project&.name
  rescue Net::ReadTimeout, Net::OpenTimeout => e
    Rails.logger.warn("Todoist nicht erreichbar (Integrations#index): #{e.message}")
    @project_name = nil
  end
end
