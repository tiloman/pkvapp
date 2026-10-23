class AiClient
  class AuthenticationError < StandardError; end

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

  private

  def auth_failure?(status)
    [401, 403].include?(status)
  end

  def connection
    @connection ||= Faraday.new(url: base_url) do |f|
      f.request :json
      f.response :json
      f.adapter Faraday.default_adapter
      f.options.timeout = 10
      f.options.open_timeout = 5
    end
  end
end
