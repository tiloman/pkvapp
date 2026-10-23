class AiClient
  class AuthenticationError < StandardError; end
  class RateLimitError < StandardError; end
  class UnreadableDocumentError < StandardError; end
  class ProviderError < StandardError; end

  # fields: { name => { type: :string | :number | :integer, enum: [...] (optional) } }
  # Every field comes back as { 'value' =>, 'confidence' => 0..1, 'evidence' => short quote }.
  Result = Struct.new(:fields, :model, :input_tokens, :output_tokens, :raw, keyword_init: true)

  EXTRACT_TIMEOUT = 60

  def self.for(provider, api_key)
    case provider.to_s
    when 'claude' then Claude.new(api_key)
    when 'gemini' then Gemini.new(api_key)
    else raise ArgumentError, "Unbekannter KI-Anbieter: #{provider}"
    end
  end

  def initialize(api_key)
    @api_key = api_key
  end

  # Cheap authenticated request; raises AuthenticationError for a rejected key.
  def validate_key!
    response = connection.get(models_path, models_params, headers)
    return true if response.status == 200

    raise AuthenticationError, 'Der API-Key wurde vom Anbieter abgelehnt.' if auth_failure?(response.status)

    raise StandardError, "#{self.class.name.demodulize}-API Fehler (#{response.status})"
  end

  # Reads a document (ActiveStorage attachment: PDF or image) into structured fields.
  def extract(document:, fields:, instructions:)
    response = connection(timeout: EXTRACT_TIMEOUT).post(
      extract_path, extract_body(document, fields, instructions), headers
    )
    raise_for_status!(response)
    parse_extraction(response.body)
  rescue Faraday::TimeoutError, Faraday::ConnectionFailed => e
    raise ProviderError, "#{provider_name} ist nicht erreichbar (#{e.class.name.demodulize})."
  end

  private

  def provider_name
    self.class.name.demodulize
  end

  def raise_for_status!(response)
    return if response.status == 200

    raise AuthenticationError, 'Der API-Key wurde vom Anbieter abgelehnt.' if auth_failure?(response.status)
    raise RateLimitError, "#{provider_name}: Rate-Limit erreicht." if response.status == 429

    raise ProviderError, "#{provider_name}-API Fehler (#{response.status})"
  end

  def encoded_document(document)
    Base64.strict_encode64(document.download)
  end

  def auth_failure?(status)
    [401, 403].include?(status)
  end

  def connection(timeout: 10)
    Faraday.new(url: base_url) do |f|
      f.request :json
      f.response :json
      f.adapter Faraday.default_adapter
      f.options.timeout = timeout
      f.options.open_timeout = 5
    end
  end
end
