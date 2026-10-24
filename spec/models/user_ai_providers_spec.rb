require 'rails_helper'

RSpec.describe User, '#ai_providers' do
  let(:user) { FactoryBot.create(:user, email: 'timo@example.com') }

  it 'is empty without integrations or local model' do
    expect(user.ai_providers).to eq([])
    expect(user).not_to be_ai_enabled
    expect(user.ai_client_for('claude')).to be_nil
  end

  it 'lists own integrations in the order they were connected' do
    AiIntegration.create!(user: user, provider: 'gemini', api_key: 'g', created_at: 2.days.ago)
    AiIntegration.create!(user: user, provider: 'claude', api_key: 'c')
    expect(user.ai_providers).to eq(%w[gemini claude])
    expect(user.ai_client_for('claude')).to be_a(AiClient::Claude)
  end

  it 'adds the local model for allowlisted users only' do
    AiLocalSetting.create!(enabled: true, base_url: 'http://laptop.lan:11434', allowed_emails: 'timo@example.com')
    expect(user.ai_providers).to eq(['local'])
    expect(user.ai_client_for('local')).to be_a(AiClient::Local)
    expect(FactoryBot.create(:user, email: 'fremd@example.com').ai_providers).to eq([])
  end

  it 'refuses a client for a provider the user cannot use' do
    AiLocalSetting.create!(enabled: true, base_url: 'http://laptop.lan:11434', allowed_emails: 'andere@example.com')
    expect(user.ai_client_for('local')).to be_nil
  end
end
