class AiClient
  class AuthenticationError < StandardError; end
  class RateLimitError < StandardError; end
  # raw: the provider's response, kept on the run so a bad answer can be inspected.
  class UnreadableDocumentError < StandardError
    attr_reader :raw

    def initialize(message = nil, raw: nil)
      super(message)
      @raw = raw
    end
  end
  class ProviderError < StandardError; end

  # fields: { name => { type: :string | :number | :integer, enum: [...] (optional) } }
  # Every field comes back as { 'value' =>, 'confidence' => 0..1, 'evidence' => short quote }.
  Result = Struct.new(:fields, :model, :input_tokens, :output_tokens, :raw, keyword_init: true)

  EXTRACT_TIMEOUT = 60

  def self.for(provider, api_key)
    case provider.to_s
    when 'claude' then Claude.new(api_key)
    when 'gemini' then Gemini.new(api_key)
    when 'local' then Local.new
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
    guard_connection do
      response = connection(timeout: extract_timeout).post(
        extract_path, extract_body(document, fields, instructions), headers
      )
      raise_for_status!(response)
      parse_extraction(response.body)
    end
  end

  private

  def guard_connection
    yield
  rescue Faraday::TimeoutError, Faraday::ConnectionFailed => e
    raise ProviderError, "#{provider_name} ist nicht erreichbar (#{e.class.name.demodulize})."
  end

  def provider_name
    self.class.name.demodulize
  end

  def extract_timeout = EXTRACT_TIMEOUT

  public

  # Longest image edge the provider should get; smaller inputs keep local models within context.
  def max_image_edge = 2000

  private

  # JSON Schema for the extraction: every field is { value, confidence, evidence }.
  def json_schema(fields)
    properties = fields.transform_values do |spec|
      value = { type: [spec[:type].to_s, 'null'] }
      value[:enum] = spec[:enum] + [nil] if spec[:enum]
      {
        type: 'object',
        properties: { value: value, confidence: { type: 'number' }, evidence: { type: %w[string null] } },
        required: %w[value confidence evidence],
        additionalProperties: false
      }
    end
    { type: 'object', properties: properties, required: fields.keys.map(&:to_s), additionalProperties: false }
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
