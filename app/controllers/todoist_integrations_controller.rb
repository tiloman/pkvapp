class TodoistIntegrationsController < ApplicationController
  require 'todoist'

  before_action :set_integration, only: %i[show edit update destroy]

  def new
    @todoist_integration = TodoistIntegration.new
  end

  def create
    @todoist_integration = TodoistIntegration.new(todoist_params.merge!(user_id: current_user.id))
    validate_token
    respond_to do |format|
      if @todoist_integration.save
        format.html { redirect_to integrations_path, notice: 'Integration wurde erstellt.' }
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
        format.html { redirect_to integrations_path, notice: 'Integration wurde aktualisiert.' }
      else
        format.html { render :edit }
      end
    end

  rescue StandardError => error
    redirect_to edit_todoist_integration_path(@todoist_integration), alert: "Fehler beim abspeichern des Tokens: #{error}"
  end

  def edit
  end

  def destroy
  end

  private

  def set_integration
    @todoist_integration = TodoistIntegration.find(params[:id])
  end

  def todoist_params
    params.require(:todoist_integration).permit(:token)
  end

  def validate_token
    Todoist::Client.create_client_by_token(@todoist_integration.token).sync
  end
end

# CREATE ITEM:
# operation = client.sync_items.add({content: "Vorgang bezahlen", due: {string: (Time.now + 1.day).strftime("%d.%m.%Y")} })
# Store item id in database

# SYNC ITEMS:
# list = client.sync_items.collection

# GET ITEM
# list[operation.id]

# UPDATE ITEM
# updated = client.sync_items.update({id: operation.id, content: 'From string', due: {string: (Time.now + 1.day).strftime("%d.%m.%Y")} })

# CLIENT VALID?
# client.present?
