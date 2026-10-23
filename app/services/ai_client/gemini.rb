class AiClient
  class Gemini < AiClient
    private

    def base_url = 'https://generativelanguage.googleapis.com'
    def models_path = 'v1beta/models'
    def models_params = { pageSize: 1 }

    def headers
      { 'x-goog-api-key' => @api_key }
    end

    # Gemini answers an invalid key with 400 API_KEY_INVALID.
    def auth_failure?(status)
      status == 400 || super
    end
  end
end
