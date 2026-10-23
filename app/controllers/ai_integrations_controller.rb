class AiIntegrationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_integration, only: %i[edit update destroy]

  def new
    @ai_integration = current_user.ai_integrations.build(provider: params[:provider])
  end

  def create
    @ai_integration = current_user.ai_integrations.build(create_params)
    if verified_and_saved?(@ai_integration)
      redirect_to integrations_path, notice: 'Integration wurde erstellt.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    @ai_integration.api_key = update_params[:api_key] if update_params[:api_key].present?
    if verified_and_saved?(@ai_integration)
      redirect_to integrations_path, notice: 'Integration wurde aktualisiert.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @ai_integration.destroy
    redirect_to integrations_path, notice: 'Integration wurde entfernt.'
  end

  private

  def set_integration
    @ai_integration = current_user.ai_integrations.find(params[:id])
  end

  def create_params
    params.require(:ai_integration).permit(:provider, :api_key)
  end

  def update_params
    params.require(:ai_integration).permit(:api_key)
  end

  def verified_and_saved?(integration)
    return false unless integration.valid?

    integration.client.validate_key!
    integration.save
  rescue AiClient::AuthenticationError => e
    integration.errors.add(:api_key, e.message)
    false
  rescue Faraday::TimeoutError, Faraday::ConnectionFailed => e
    Rails.logger.warn("KI-Anbieter nicht erreichbar (#{integration.provider}): #{e.message}")
    integration.errors.add(:base, 'Der Anbieter ist derzeit nicht erreichbar. Bitte später erneut versuchen.')
    false
  rescue StandardError => e
    Rails.logger.warn("KI-Key konnte nicht geprüft werden (#{integration.provider}): #{e.message}")
    integration.errors.add(:base, 'Der API-Key konnte nicht geprüft werden.')
    false
  end
end
