class AiClient
  class Gemini < AiClient
    MODEL = ENV.fetch('AI_GEMINI_MODEL', 'gemini-flash-latest')

    private

    def base_url = 'https://generativelanguage.googleapis.com'
    def models_path = 'v1beta/models'
    def models_params = { pageSize: 1 }
    def extract_path = "v1beta/models/#{MODEL}:generateContent"

    def headers
      { 'x-goog-api-key' => @api_key }
    end

    # Gemini answers an invalid key with 400 API_KEY_INVALID.
    def auth_failure?(status)
      status == 400 || super
    end

    def extract_body(document, fields, instructions)
      {
        contents: [{ parts: [
          { inline_data: { mime_type: document.content_type, data: encoded_document(document) } },
          { text: instructions }
        ] }],
        generationConfig: { responseMimeType: 'application/json', responseSchema: schema(fields) }
      }
    end

    def schema(fields)
      properties = fields.transform_values do |spec|
        value = { type: spec[:type].to_s.upcase, nullable: true }
        value[:enum] = spec[:enum] if spec[:enum]
        {
          type: 'OBJECT',
          properties: { value: value, confidence: { type: 'NUMBER' }, evidence: { type: 'STRING', nullable: true } },
          required: %w[value confidence evidence]
        }
      end
      { type: 'OBJECT', properties: properties, required: fields.keys.map(&:to_s) }
    end

    def parse_extraction(body)
      text = body.dig('candidates', 0, 'content', 'parts', 0, 'text')
      raise UnreadableDocumentError, 'Gemini hat keine Felder zurückgegeben.' if text.blank?

      usage = body['usageMetadata'] || {}
      Result.new(fields: JSON.parse(text), model: body['modelVersion'] || MODEL,
                 input_tokens: usage['promptTokenCount'], output_tokens: usage['candidatesTokenCount'], raw: body)
    rescue JSON::ParserError
      raise UnreadableDocumentError, 'Gemini hat ungültiges JSON zurückgegeben.'
    end
  end
end
