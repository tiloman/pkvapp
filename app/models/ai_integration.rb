class AiIntegration < ApplicationRecord
  PROVIDERS = %w[claude gemini].freeze

  belongs_to :user
  has_encrypted :api_key

  validates :provider, inclusion: { in: PROVIDERS }, uniqueness: { scope: :user_id }
  validates :api_key, presence: true

  def client
    AiClient.for(provider, api_key)
  end

  def masked_api_key
    "••••#{api_key.to_s.last(4)}"
  end
end
