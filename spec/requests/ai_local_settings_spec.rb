require 'rails_helper'

RSpec.describe 'AiLocalSettings', type: :request do
  include Devise::Test::IntegrationHelpers

  let(:admin) { FactoryBot.create(:user, admin: true) }
  let(:member) { FactoryBot.create(:user, email: 'member@example.com') }
  let(:valid_params) do
    { ai_local_setting: { enabled: '1', base_url: 'http://192.168.178.50:11434', model: 'qwen2.5vl:7b',
                          allowed_emails: "#{admin.email}\nmember@example.com" } }
  end

  before do
    allow_any_instance_of(ActionView::Base).to receive(:javascript_pack_tag).and_return('')
    allow_any_instance_of(ActionView::Base).to receive(:stylesheet_pack_tag).and_return('')
  end

  context 'as a normal user' do
    before { sign_in member }

    it 'cannot open or change the settings' do
      get edit_ai_local_setting_path
      expect(response).to redirect_to(integrations_path)

      patch ai_local_setting_path, params: valid_params
      expect(response).to redirect_to(integrations_path)
      expect(AiLocalSetting.count).to eq(0)

      post test_ai_local_setting_path
      expect(response).to redirect_to(integrations_path)
    end

    it 'cannot grant itself admin through the settings form' do
      patch ai_local_setting_path, params: valid_params.deep_merge(ai_local_setting: { admin: true })
      expect(member.reload.admin?).to be(false)
    end
  end

  context 'as an admin' do
    before { sign_in admin }

    it 'shows the form' do
      get edit_ai_local_setting_path
      expect(response).to be_successful
      expect(response.body).to include('Verbindung testen')
    end

    it 'saves the settings' do
      patch ai_local_setting_path, params: valid_params
      expect(response).to redirect_to(edit_ai_local_setting_path)
      setting = AiLocalSetting.current
      expect([setting.enabled, setting.base_url]).to eq([true, 'http://192.168.178.50:11434'])
      expect(setting.allowed_email_list).to contain_exactly(admin.email.downcase, 'member@example.com')
    end

    it 'updates the single existing row instead of adding another' do
      2.times { patch ai_local_setting_path, params: valid_params }
      expect(AiLocalSetting.count).to eq(1)
    end

    it 'keeps the api key when left blank and removes it on request' do
      patch ai_local_setting_path, params: valid_params.deep_merge(ai_local_setting: { api_key: 'tok-1234' })
      patch ai_local_setting_path, params: valid_params.deep_merge(ai_local_setting: { api_key: '' })
      expect(AiLocalSetting.current.api_key).to eq('tok-1234')

      patch ai_local_setting_path, params: valid_params.deep_merge(ai_local_setting: { clear_api_key: '1' })
      expect(AiLocalSetting.current.api_key).to be_blank
    end

    it 're-renders with errors for an invalid url' do
      patch ai_local_setting_path, params: valid_params.deep_merge(ai_local_setting: { base_url: 'file:///etc/passwd' })
      expect(response).to have_http_status(:unprocessable_entity)
      expect(AiLocalSetting.count).to eq(0)
    end

    describe 'POST test' do
      before { AiLocalSetting.create!(enabled: true, base_url: 'http://laptop.lan:11434', model: 'qwen-test') }

      it 'reports a reachable server with the model' do
        stub_request(:get, 'http://laptop.lan:11434/v1/models').to_return(
          status: 200, headers: { 'Content-Type' => 'application/json' }, body: { data: [{ id: 'qwen-test' }] }.to_json
        )
        post test_ai_local_setting_path
        expect(flash[:notice]).to include('Erreichbar')
      end

      it 'names the models that exist when the configured one is missing' do
        stub_request(:get, 'http://laptop.lan:11434/v1/models').to_return(
          status: 200, headers: { 'Content-Type' => 'application/json' }, body: { data: [{ id: 'llama3' }] }.to_json
        )
        post test_ai_local_setting_path
        expect(flash[:alert]).to include('fehlt').and include('llama3')
      end

      it 'reports an unreachable server' do
        stub_request(:get, 'http://laptop.lan:11434/v1/models').to_timeout
        post test_ai_local_setting_path
        expect(flash[:alert]).to include('nicht erreichbar')
      end
    end

    it 'asks to save an address before testing' do
      post test_ai_local_setting_path
      expect(flash[:alert]).to include('zuerst')
    end

    it 'shows the settings card on the integrations page' do
      AiLocalSetting.create!(enabled: true, base_url: 'http://laptop.lan:11434')
      get integrations_path
      expect(response.body).to include('laptop.lan').and include('Einstellungen')
    end
  end
end
