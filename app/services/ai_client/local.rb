class AiClient
  # A model served on the operator's own machine (Ollama, LM Studio, llama.cpp) through the
  # OpenAI-compatible API. URL, model and allowed users come from AiLocalSetting, which only
  # admins can edit (see there for why).
  class Local < AiClient
    LOCAL_TIMEOUT = 300
    CHECK_TIMEOUT = 5

    Check = Struct.new(:models, :model_available, keyword_init: true)

    def self.available_for?(user)
      AiLocalSetting.current.usable_by?(user)
    end

    def initialize(setting = AiLocalSetting.current)
      super(setting.api_key.presence)
      @setting = setting
    end

    # Cheap reachability test for the settings page: lists the models the server offers.
    def check
      guard_connection do
        response = connection(timeout: CHECK_TIMEOUT).get('v1/models', {}, headers)
        raise_for_status!(response)
        data = response.body.is_a?(Hash) ? response.body['data'] : nil
        raise ProviderError, "#{provider_name}: Der Server antwortet nicht im OpenAI-Format." unless data.is_a?(Array)

        ids = data.filter_map { |entry| entry['id'] if entry.is_a?(Hash) }
        Check.new(models: ids, model_available: ids.any? { |id| [model, "#{model}:latest"].include?(id) })
      end
    end

    private

    def provider_name = 'Lokales Modell'
    def base_url = @setting.base_url.to_s
    def model = @setting.model
    def extract_path = 'v1/chat/completions'
    def extract_timeout = LOCAL_TIMEOUT

    def headers
      @api_key.present? ? { 'Authorization' => "Bearer #{@api_key}" } : {}
    end

    def extract_body(document, fields, instructions)
      images = DocumentPages.call(document).map do |page|
        { type: 'image_url', image_url: { url: "data:#{page.content_type};base64,#{Base64.strict_encode64(page.data)}" } }
      end
      {
        model: model,
        temperature: 0,
        messages: [{ role: 'user', content: images + [{ type: 'text', text: instructions }] }],
        response_format: { type: 'json_schema', json_schema: { name: 'extraction', strict: true,
                                                                schema: json_schema(fields) } }
      }
    end

    def parse_extraction(body)
      raise ProviderError, "#{provider_name}: Der Server antwortet nicht im OpenAI-Format." unless body.is_a?(Hash)

      text = body.dig('choices', 0, 'message', 'content')
      raise UnreadableDocumentError, 'Das lokale Modell hat keine Felder zurückgegeben.' if text.blank?

      fields = JSON.parse(text)
      raise UnreadableDocumentError, 'Das lokale Modell hat ungültige Felder zurückgegeben.' unless fields.is_a?(Hash)

      usage = body['usage'] || {}
      Result.new(fields: fields, model: body['model'] || model,
                 input_tokens: usage['prompt_tokens'], output_tokens: usage['completion_tokens'], raw: body)
    rescue JSON::ParserError
      raise UnreadableDocumentError, 'Das lokale Modell hat ungültiges JSON zurückgegeben.'
    end

    # Local servers explain themselves (unknown model, no vision support); pass that on.
    def raise_for_status!(response)
      super
    rescue ProviderError => e
      error = response.body.is_a?(Hash) ? response.body['error'] : nil
      detail = (error.is_a?(Hash) ? error['message'] : error).to_s.truncate(200)
      raise ProviderError, "#{e.message}: #{detail}" if detail.present?

      raise
    end
  end
end
