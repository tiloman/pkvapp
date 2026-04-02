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

    client = TodoistClient.new(@todoist_integration.token)
    project = client.projects.find { |p| p["id"] == @todoist_integration.project_id }
    @project_name = project&.dig("name")
  rescue Faraday::TimeoutError, Faraday::ConnectionFailed => e
    Rails.logger.warn("Todoist nicht erreichbar (Integrations#index): #{e.message}")
    @project_name = nil
  end
end
