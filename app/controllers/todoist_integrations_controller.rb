class TodoistIntegrationsController < ApplicationController
  before_action :set_integration, only: %i[show edit update destroy]

  def new
    @todoist_integration = TodoistIntegration.new
  end

  def create
    @todoist_integration = TodoistIntegration.new(todoist_params.merge!(user_id: current_user.id))

     respond_to do |format|
      if @todoist_integration.save
        format.html { redirect_to integrations_path, notice: 'Integration wurde erstellt.' }
      else
        format.html { render :new, error: ' Es ist ein Fehler aufgetreten' }
      end
    end
  end

  def update
     respond_to do |format|
      if @todoist_integration.update(todoist_params.merge!(user_id: current_user.id))
        format.html { redirect_to integrations_path, notice: 'Integration wurde aktualisiert.' }
      else
        format.html { render :edit }
      end
    end
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
    params.require(:todoist_integration).permit(:email, :password, :token)
  end

end
