# App-wide settings of the local AI provider (a model on the operator's own machine).
# Only admins may edit it: a user-controlled URL would let any account make the server
# call arbitrary internal hosts (server-side request forgery).
class AiLocalSetting < ApplicationRecord
  DEFAULT_MODEL = 'qwen2.5vl:7b'.freeze

  has_encrypted :api_key

  before_validation :normalize

  validates :model, presence: true
  validates :base_url, presence: true, if: :enabled?
  validate :base_url_is_http_url
  validate :emails_are_valid

  def self.current
    first || new(model: DEFAULT_MODEL)
  end

  def allowed_email_list
    allowed_emails.to_s.split(/[\s,;]+/).map(&:downcase).reject(&:empty?).uniq
  end

  def usable_by?(user)
    enabled? && base_url.present? && allowed_email_list.include?(user.email.to_s.downcase)
  end

  def masked_api_key
    api_key.present? ? "••••#{api_key.last(4)}" : nil
  end

  private

  # "http://host:11434/v1/" -> "http://host:11434"; the client appends the API path itself.
  def normalize
    self.base_url = base_url.to_s.strip.sub(%r{/v1/?\z}, '').chomp('/').presence
    self.model = model.to_s.strip
    self.allowed_emails = allowed_email_list.join("\n")
  end

  def base_url_is_http_url
    return if base_url.blank?

    uri = URI.parse(base_url)
    valid = uri.is_a?(URI::HTTP) && uri.host.present? && uri.userinfo.nil?
    errors.add(:base_url, 'muss eine http(s)-Adresse ohne Zugangsdaten sein, z. B. http://192.168.178.50:11434') unless valid
  rescue URI::InvalidURIError
    errors.add(:base_url, 'ist keine gültige Adresse')
  end

  def emails_are_valid
    invalid = allowed_email_list.grep_v(URI::MailTo::EMAIL_REGEXP)
    errors.add(:allowed_emails, "enthält ungültige Adressen: #{invalid.join(', ')}") if invalid.any?
  end
end
