require 'rails_helper'

RSpec.describe AiLocalSetting, type: :model do
  def build(attrs = {})
    described_class.new({ enabled: true, base_url: 'http://192.168.178.50:11434' }.merge(attrs))
  end

  it 'has defaults and is valid when disabled and empty' do
    expect(described_class.current.model).to eq('qwen2.5vl:7b')
    expect(described_class.new(enabled: false)).to be_valid
  end

  it 'needs a url once enabled' do
    expect(build(base_url: '')).not_to be_valid
  end

  it 'normalizes the url' do
    expect(build(base_url: ' http://host:11434/v1/ ').tap(&:validate).base_url).to eq('http://host:11434')
    expect(build(base_url: 'https://host/').tap(&:validate).base_url).to eq('https://host')
  end

  it 'accepts only plain http(s) urls without credentials' do
    expect(build(base_url: 'file:///etc/passwd')).not_to be_valid
    expect(build(base_url: 'ftp://host')).not_to be_valid
    expect(build(base_url: 'not a url')).not_to be_valid
    expect(build(base_url: 'http://user:pw@host:11434')).not_to be_valid
    expect(build(base_url: 'https://tailnet-laptop.ts.net')).to be_valid
  end

  it 'normalizes and validates the allowed emails' do
    setting = build(allowed_emails: "Timo@Example.com, anna@example.com;\n timo@example.com")
    expect(setting).to be_valid
    expect(setting.allowed_emails).to eq("timo@example.com\nanna@example.com")
    expect(build(allowed_emails: 'kein-email, ok@example.com')).not_to be_valid
  end

  describe '#usable_by?' do
    let(:setting) { build(allowed_emails: 'timo@example.com') }

    it 'requires enabled, a url and an allowlisted email' do
      expect(setting.usable_by?(User.new(email: 'TIMO@example.com'))).to be(true)
      expect(setting.usable_by?(User.new(email: 'fremd@example.com'))).to be(false)
      expect(build(enabled: false, allowed_emails: 'timo@example.com').usable_by?(User.new(email: 'timo@example.com'))).to be(false)
    end
  end

  it 'stores the api key encrypted' do
    setting = build(api_key: 'token-1234').tap(&:save!)
    expect(setting.api_key_ciphertext).not_to include('token-1234')
    expect(setting.reload.api_key).to eq('token-1234')
    expect(setting.masked_api_key).to eq('••••1234')
  end
end
