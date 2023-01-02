class IntegrationsController < ApplicationController

  def index
    @todoist_integration = current_user.todoist_integration
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

end
