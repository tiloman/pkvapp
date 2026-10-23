require 'rails_helper'

RSpec.describe 'AiClient#extract' do
  let(:fields) do
    {
      total_amount: { type: :number },
      document_type: { type: :string, enum: %w[bill reminder other] }
    }
  end
  let(:extraction) do
    {
      'total_amount' => { 'value' => 42.5, 'confidence' => 0.95, 'evidence' => 'Summe 42,50 EUR' },
      'document_type' => { 'value' => 'bill', 'confidence' => 0.99, 'evidence' => 'Rechnung' }
    }
  end
  let(:content_type) { 'application/pdf' }
  let(:document) { Struct.new(:content_type, :download).new(content_type, 'pdf-bytes') }

  def extract(client)
    client.extract(document: document, fields: fields, instructions: 'Lies die Rechnung.')
  end

  describe AiClient::Claude do
    let(:client) { described_class.new('sk-test') }
    let(:url) { 'https://api.anthropic.com/v1/messages' }

    it 'sends the document with a forced tool and parses the tool input' do
      stub = stub_request(:post, url)
             .with(headers: { 'x-api-key' => 'sk-test' }) { |req|
               body = JSON.parse(req.body)
               block = body['messages'][0]['content'][0]
               block['type'] == 'document' &&
                 block['source']['data'] == Base64.strict_encode64('pdf-bytes') &&
                 body['tool_choice'] == { 'type' => 'tool', 'name' => 'record_extraction' } &&
                 body['tools'][0]['input_schema']['properties'].key?('total_amount')
             }
             .to_return(status: 200, headers: { 'Content-Type' => 'application/json' },
                        body: { model: 'claude-x', usage: { input_tokens: 12, output_tokens: 7 },
                                content: [{ type: 'tool_use', name: 'record_extraction', input: extraction }] }.to_json)

      result = extract(client)
      expect(stub).to have_been_requested
      expect(result.fields).to eq(extraction)
      expect(result.model).to eq('claude-x')
      expect([result.input_tokens, result.output_tokens]).to eq([12, 7])
    end

    context 'with an image' do
      let(:content_type) { 'image/jpeg' }

      it 'uses an image block' do
        stub_request(:post, url).with { |req| JSON.parse(req.body)['messages'][0]['content'][0]['type'] == 'image' }
                                .to_return(status: 200, headers: { 'Content-Type' => 'application/json' },
                                           body: { content: [{ type: 'tool_use', input: extraction }] }.to_json)
        expect(extract(client).fields).to eq(extraction)
      end
    end

    it 'raises when no tool call comes back' do
      stub_request(:post, url).to_return(status: 200, headers: { 'Content-Type' => 'application/json' },
                                         body: { content: [{ type: 'text', text: 'hm' }] }.to_json)
      expect { extract(client) }.to raise_error(AiClient::UnreadableDocumentError)
    end

    it 'maps status codes to errors' do
      stub_request(:post, url).to_return(status: 401, body: '{}', headers: { 'Content-Type' => 'application/json' })
      expect { extract(client) }.to raise_error(AiClient::AuthenticationError)

      stub_request(:post, url).to_return(status: 429, body: '{}', headers: { 'Content-Type' => 'application/json' })
      expect { extract(client) }.to raise_error(AiClient::RateLimitError)

      stub_request(:post, url).to_return(status: 500, body: '{}', headers: { 'Content-Type' => 'application/json' })
      expect { extract(client) }.to raise_error(AiClient::ProviderError)
    end

    it 'wraps timeouts' do
      stub_request(:post, url).to_timeout
      expect { extract(client) }.to raise_error(AiClient::ProviderError)
    end
  end

  describe AiClient::Gemini do
    let(:client) { described_class.new('g-key') }
    let(:url) { "https://generativelanguage.googleapis.com/v1beta/models/#{described_class::MODEL}:generateContent" }

    it 'requests JSON output with a schema and parses the text part' do
      stub = stub_request(:post, url)
             .with(headers: { 'x-goog-api-key' => 'g-key' }) { |req|
               body = JSON.parse(req.body)
               body['generationConfig']['responseMimeType'] == 'application/json' &&
                 body['contents'][0]['parts'][0]['inline_data']['mime_type'] == 'application/pdf' &&
                 body['generationConfig']['responseSchema']['properties']['document_type']['properties']['value']['enum'] == %w[bill reminder other]
             }
             .to_return(status: 200, headers: { 'Content-Type' => 'application/json' },
                        body: { modelVersion: 'gemini-x', usageMetadata: { promptTokenCount: 20, candidatesTokenCount: 9 },
                                candidates: [{ content: { parts: [{ text: extraction.to_json }] } }] }.to_json)

      result = extract(client)
      expect(stub).to have_been_requested
      expect(result.fields).to eq(extraction)
      expect([result.model, result.input_tokens, result.output_tokens]).to eq(['gemini-x', 20, 9])
    end

    it 'raises on invalid json' do
      stub_request(:post, url).to_return(status: 200, headers: { 'Content-Type' => 'application/json' },
                                         body: { candidates: [{ content: { parts: [{ text: 'nope' }] } }] }.to_json)
      expect { extract(client) }.to raise_error(AiClient::UnreadableDocumentError)
    end

    it 'treats 400 as rejected key and 429 as rate limit' do
      stub_request(:post, url).to_return(status: 400, body: '{}', headers: { 'Content-Type' => 'application/json' })
      expect { extract(client) }.to raise_error(AiClient::AuthenticationError)

      stub_request(:post, url).to_return(status: 429, body: '{}', headers: { 'Content-Type' => 'application/json' })
      expect { extract(client) }.to raise_error(AiClient::RateLimitError)
    end
  end
end
