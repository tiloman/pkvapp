class AiClient
  class Claude < AiClient
    MODEL = ENV.fetch('AI_CLAUDE_MODEL', 'claude-haiku-4-5-20251001')
    TOOL_NAME = 'record_extraction'.freeze

    private

    def base_url = 'https://api.anthropic.com'
    def models_path = 'v1/models'
    def models_params = { limit: 1 }
    def extract_path = 'v1/messages'

    def headers
      { 'x-api-key' => @api_key, 'anthropic-version' => '2023-06-01' }
    end

    def extract_body(document, fields, instructions)
      {
        model: MODEL,
        max_tokens: 2000,
        tools: [{ name: TOOL_NAME, description: 'Gibt die aus dem Dokument gelesenen Felder zurück.',
                  input_schema: schema(fields) }],
        tool_choice: { type: 'tool', name: TOOL_NAME },
        messages: [{ role: 'user', content: [document_block(document), { type: 'text', text: instructions }] }]
      }
    end

    def document_block(document)
      type = document.content_type == 'application/pdf' ? 'document' : 'image'
      { type: type, source: { type: 'base64', media_type: document.content_type, data: encoded_document(document) } }
    end

    def schema(fields)
      properties = fields.transform_values do |spec|
        value = { type: [spec[:type].to_s, 'null'] }
        value[:enum] = spec[:enum] + [nil] if spec[:enum]
        {
          type: 'object',
          properties: { value: value, confidence: { type: 'number' }, evidence: { type: %w[string null] } },
          required: %w[value confidence evidence]
        }
      end
      { type: 'object', properties: properties, required: fields.keys.map(&:to_s) }
    end

    def parse_extraction(body)
      block = Array(body['content']).find { |b| b['type'] == 'tool_use' }
      raise UnreadableDocumentError, 'Claude hat keine Felder zurückgegeben.' unless block

      usage = body['usage'] || {}
      Result.new(fields: block['input'], model: body['model'] || MODEL,
                 input_tokens: usage['input_tokens'], output_tokens: usage['output_tokens'], raw: body)
    end
  end
end
