require 'rails_helper'

RSpec.describe AiClient::Local do
  let(:fields) { { total_amount: { type: :number }, document_type: { type: :string, enum: %w[bill other] } } }
  let(:extraction) do
    {
      'total_amount' => { 'value' => 42.5, 'confidence' => 0.8, 'evidence' => 'Summe 42,50' },
      'document_type' => { 'value' => 'bill', 'confidence' => 0.9, 'evidence' => 'Rechnung' }
    }
  end
  let(:document) { Struct.new(:content_type, :download).new('image/png', 'png-bytes') }
  let(:url) { 'http://laptop.lan:11434/v1/chat/completions' }
  let(:json) { { 'Content-Type' => 'application/json' } }

  let!(:setting) do
    AiLocalSetting.create!(enabled: true, base_url: 'http://laptop.lan:11434/', model: 'qwen-test',
                           allowed_emails: 'timo@example.com')
  end

  def extract
    described_class.new(setting).extract(document: document, fields: fields, instructions: 'Lies.')
  end

  def completion(content, extra = {})
    { model: 'qwen-test', usage: { prompt_tokens: 30, completion_tokens: 11 },
      choices: [{ message: { content: content } }] }.merge(extra).to_json
  end

  describe '.available_for?' do
    it 'is true for allowlisted users of an enabled setting' do
      expect(described_class.available_for?(User.new(email: 'Timo@Example.com'))).to be(true)
      expect(described_class.available_for?(User.new(email: 'x@example.com'))).to be(false)
    end

    it 'is off when the setting is disabled' do
      setting.update!(enabled: false)
      expect(described_class.available_for?(User.new(email: 'timo@example.com'))).to be(false)
    end
  end

  describe '#check' do
    it 'lists the models and reports whether the configured one is there' do
      stub_request(:get, 'http://laptop.lan:11434/v1/models')
        .to_return(status: 200, headers: json, body: { data: [{ id: 'llama3' }, { id: 'qwen-test:latest' }] }.to_json)
      check = described_class.new(setting).check
      expect(check.models).to eq(%w[llama3 qwen-test:latest])
      expect(check.model_available).to be(true)
    end

    it 'reports a missing model' do
      stub_request(:get, 'http://laptop.lan:11434/v1/models')
        .to_return(status: 200, headers: json, body: { data: [{ id: 'llama3' }] }.to_json)
      expect(described_class.new(setting).check.model_available).to be(false)
    end

    it 'rejects servers that do not speak the OpenAI format' do
      stub_request(:get, 'http://laptop.lan:11434/v1/models')
        .to_return(status: 200, headers: { 'Content-Type' => 'text/html' }, body: '<html>router</html>')
      expect { described_class.new(setting).check }.to raise_error(AiClient::ProviderError, /OpenAI-Format/)
    end

    it 'reports an unreachable server' do
      stub_request(:get, 'http://laptop.lan:11434/v1/models').to_timeout
      expect { described_class.new(setting).check }.to raise_error(AiClient::ProviderError, /nicht erreichbar/)
    end
  end

  it 'sends page images and a json schema, then parses the message content' do
    stub = stub_request(:post, url).with { |req|
      body = JSON.parse(req.body)
      content = body['messages'][0]['content']
      body['model'] == 'qwen-test' && body['temperature'] == 0 &&
        content[0]['image_url']['url'] == "data:image/png;base64,#{Base64.strict_encode64('png-bytes')}" &&
        content.last == { 'type' => 'text', 'text' => 'Lies.' } &&
        body['response_format']['type'] == 'json_schema' &&
        body['response_format']['json_schema']['schema']['properties'].key?('total_amount') &&
        !req.headers.key?('Authorization')
    }.to_return(status: 200, headers: json, body: completion(extraction.to_json))

    result = extract
    expect(stub).to have_been_requested
    expect(result.fields).to eq(extraction)
    expect([result.model, result.input_tokens, result.output_tokens]).to eq(['qwen-test', 30, 11])
  end

  it 'sends an optional bearer token' do
    setting.update!(api_key: 'secret')
    stub = stub_request(:post, url).with(headers: { 'Authorization' => 'Bearer secret' })
                                   .to_return(status: 200, headers: json, body: completion(extraction.to_json))
    extract
    expect(stub).to have_been_requested
  end

  it 'renders a pdf into one image per page' do
    pdf = Struct.new(:content_type, :download).new('application/pdf', '%PDF')
    pages = [DocumentPages::Page.new('image/png', 'a'), DocumentPages::Page.new('image/png', 'b')]
    allow(DocumentPages).to receive(:call).with(pdf).and_return(pages)
    stub = stub_request(:post, url).with { |req|
      JSON.parse(req.body)['messages'][0]['content'].count { |c| c['type'] == 'image_url' } == 2
    }.to_return(status: 200, headers: json, body: completion(extraction.to_json))

    described_class.new.extract(document: pdf, fields: fields, instructions: 'Lies.')
    expect(stub).to have_been_requested
  end

  it 'raises for empty or invalid model output' do
    stub_request(:post, url).to_return(status: 200, headers: json, body: completion(''))
    expect { extract }.to raise_error(AiClient::UnreadableDocumentError)

    stub_request(:post, url).to_return(status: 200, headers: json, body: completion('kein json'))
    expect { extract }.to raise_error(AiClient::UnreadableDocumentError)

    stub_request(:post, url).to_return(status: 200, headers: json, body: completion('[1,2]'))
    expect { extract }.to raise_error(AiClient::UnreadableDocumentError)
  end

  it 'passes on the explanation of the local server' do
    stub_request(:post, url).to_return(status: 404, headers: json, body: { error: { message: "model 'qwen-test' not found" } }.to_json)
    expect { extract }.to raise_error(AiClient::ProviderError, /not found/)

    stub_request(:post, url).to_return(status: 400, headers: json, body: { error: 'does not support images' }.to_json)
    expect { extract }.to raise_error(AiClient::ProviderError, /does not support images/)
  end

  it 'reports an unreachable laptop in plain words' do
    stub_request(:post, url).to_timeout
    expect { extract }.to raise_error(AiClient::ProviderError, /Lokales Modell ist nicht erreichbar/)
  end
end
