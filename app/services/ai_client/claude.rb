class AiClient
  class Claude < AiClient
    private

    def base_url = 'https://api.anthropic.com'
    def models_path = 'v1/models'
    def models_params = { limit: 1 }

    def headers
      { 'x-api-key' => @api_key, 'anthropic-version' => '2023-06-01' }
    end
  end
end
