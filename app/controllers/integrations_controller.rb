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
    @project_name = client.sync_projects.collection[@todoist_integration.project_id].name
  end
end
