class TodoistIntegrationsController < ApplicationController
  require 'todoist'

  before_action :authenticate_user!
  before_action :set_integration, only: %i[show edit update destroy]

  def new
    @todoist_integration = TodoistIntegration.new
  end

  def create
    @todoist_integration = TodoistIntegration.new(todoist_params.merge!(user_id: current_user.id))
    validate_token
    respond_to do |format|
      if @todoist_integration.save
        format.html { redirect_to edit_todoist_integration_path(@todoist_integration), notice: 'Integration wurde erstellt.' }
      else
        format.html { render :new, alert: ' Es ist ein Fehler aufgetreten' }
      end
    end

  rescue StandardError => error
    redirect_to new_todoist_integration_path, alert: "Fehler beim abspeichern des Tokens: #{error}"
  end

  def update
    validate_token
    respond_to do |format|
      if @todoist_integration.update(todoist_params.merge!(user_id: current_user.id))
        format.html { redirect_to edit_todoist_integration_path(@todoist_integration), notice: 'Integration wurde aktualisiert.' }
      else
        format.html { render :edit }
      end
    end

  rescue StandardError => error
    redirect_to edit_todoist_integration_path(@todoist_integration), alert: "Fehler beim abspeichern des Tokens: #{error}"
  end

  def edit
    get_projects
  end

  def destroy
    @todoist_integration.destroy
    respond_to do |format|
      format.html { redirect_to integrations_path, notice: 'Integration wurde entfernt.' }
      format.json { head :no_content }
    end
  end

  private

  def set_integration
    @todoist_integration = TodoistIntegration.find(params[:id])
  end

  def todoist_params
    params.require(:todoist_integration).permit(:token, :project_id)
  end

  def validate_token
    todoist_client
    @todoist_client.sync
  end

  def todoist_client
    @todoist_client = Todoist::Client.create_client_by_token(@todoist_integration.token)
  end

  def get_projects
    todoist_client
    @projects = @todoist_client.sync_projects.collection.map { |project| [project[1].name, project[0]] }
  end
end
