require 'rails_helper'

RSpec.describe AiIntegration, type: :model do
  let(:user) { FactoryBot.create(:user) }

  it 'is valid with provider and api key' do
    expect(described_class.new(user: user, provider: 'claude', api_key: 'sk-test')).to be_valid
  end

  it 'rejects unknown providers' do
    expect(described_class.new(user: user, provider: 'foo', api_key: 'x')).not_to be_valid
  end

  it 'requires an api key' do
    expect(described_class.new(user: user, provider: 'gemini')).not_to be_valid
  end

  it 'allows one integration per provider and user' do
    described_class.create!(user: user, provider: 'claude', api_key: 'a')
    expect(described_class.new(user: user, provider: 'claude', api_key: 'b')).not_to be_valid
    expect(described_class.new(user: user, provider: 'gemini', api_key: 'b')).to be_valid
  end

  it 'stores the api key encrypted' do
    integration = described_class.create!(user: user, provider: 'claude', api_key: 'sk-secret')
    expect(integration.api_key_ciphertext).not_to include('sk-secret')
    expect(integration.reload.api_key).to eq('sk-secret')
    expect(integration.masked_api_key).to eq('••••cret')
  end
end
