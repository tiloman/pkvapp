class AiLocalSettingsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin
  before_action :set_setting

  def edit; end

  def update
    @setting.assign_attributes(setting_params)
    @setting.api_key = params.dig(:ai_local_setting, :api_key) if params.dig(:ai_local_setting, :api_key).present?
    @setting.api_key = nil if params.dig(:ai_local_setting, :clear_api_key) == '1'

    if @setting.save
      redirect_to edit_ai_local_setting_path, notice: 'Einstellungen wurden gespeichert.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # Tests the saved settings, so unsaved edits are not what gets checked.
  def test
    return redirect_to(edit_ai_local_setting_path, alert: 'Bitte zuerst eine Adresse speichern.') if @setting.base_url.blank?

    check = AiClient::Local.new(@setting).check
    if check.model_available
      redirect_to edit_ai_local_setting_path, notice: "Erreichbar. Modell #{@setting.model} ist vorhanden."
    else
      available = check.models.first(8).join(', ').presence || 'keine'
      redirect_to edit_ai_local_setting_path,
                  alert: "Erreichbar, aber das Modell #{@setting.model} fehlt. Vorhanden: #{available}"
    end
  rescue AiClient::AuthenticationError, AiClient::ProviderError => e
    redirect_to edit_ai_local_setting_path, alert: e.message
  end

  private

  def require_admin
    redirect_to integrations_path, alert: 'Nur Administratoren können das ändern.' unless current_user.admin?
  end

  def set_setting
    @setting = AiLocalSetting.current
  end

  def setting_params
    params.require(:ai_local_setting).permit(:enabled, :base_url, :model, :allowed_emails)
  end
end
