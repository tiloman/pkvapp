require 'rails_helper'
require_relative 'ai_run_helpers'

RSpec.describe ExtractBill do
  let(:user) { FactoryBot.create(:user) }
  let(:client) { instance_double(AiClient::Claude) }
  let(:run) { create_run(user, status: 'processing', output: {}) }
  let(:result) do
    AiClient::Result.new(fields: bill_output, model: 'claude-x', input_tokens: 10, output_tokens: 5, raw: { 'id' => 'msg' })
  end

  before do
    AiIntegration.create!(user: user, provider: 'claude', api_key: 'sk-test')
    allow(AiClient).to receive(:for).with('claude', 'sk-test').and_return(client)
  end

  it 'stores the extraction and moves the run to proposed' do
    allow(client).to receive(:extract).and_return(result)

    expect(described_class.call(ai_run: run)).to be_a_success
    run.reload
    expect(run).to be_proposed
    expect(run.output['total_amount']['value']).to eq(123.456)
    expect([run.model, run.input_tokens, run.output_tokens]).to eq(['claude-x', 10, 5])
    expect(run.prompt_version).to eq('bill-v1')
    expect(run.raw_response).to eq('id' => 'msg')
  end

  it 'passes the document, field schema and instructions to the client' do
    expect(client).to receive(:extract).with(
      hash_including(fields: described_class::FIELDS, instructions: described_class::INSTRUCTIONS)
    ).and_return(result)
    described_class.call(ai_run: run)
  end

  it 'marks the run failed with a message on provider errors' do
    allow(client).to receive(:extract).and_raise(AiClient::AuthenticationError, 'abgelehnt')

    expect(described_class.call(ai_run: run)).to be_a_failure
    expect(run.reload).to be_failed
    expect(run.error_message).to eq('abgelehnt')
  end

  it 'fails when the provider integration is missing' do
    run.update!(provider: 'gemini')
    expect(described_class.call(ai_run: run)).to be_a_failure
    expect(run.reload).to be_failed
  end

  it 'fails the run when the stored file is gone' do
    allow(client).to receive(:extract).and_raise(ActiveStorage::FileNotFoundError)

    expect(described_class.call(ai_run: run)).to be_a_failure
    expect(run.reload).to be_failed
    expect(run.error_message).to include('fehlt im Speicher')
  end

  it 'fails the run instead of leaving it processing on unexpected errors' do
    allow(client).to receive(:extract).and_raise(NoMethodError, 'boom')
    expect(Rails.logger).to receive(:error).with(/NoMethodError: boom/)

    expect(described_class.call(ai_run: run)).to be_a_failure
    expect(run.reload).to be_failed
    expect(run.error_message).to include('NoMethodError')
  end

  it 'lets rate limit errors through for the job to retry' do
    allow(client).to receive(:extract).and_raise(AiClient::RateLimitError)
    expect { described_class.call(ai_run: run) }.to raise_error(AiClient::RateLimitError)
    expect(run.reload).to be_processing
  end

  it 'falls back to the original when an image cannot be resized' do
    image_run = AiRun.new(user: user, kind: 'extract_bill', provider: 'claude')
    image_run.document.attach(io: StringIO.new('not-an-image'), filename: 'a.jpg', content_type: 'image/jpeg')
    image_run.save!
    expect(client).to receive(:extract) do |document:, **|
      expect(document.download).to eq('not-an-image')
      result
    end
    expect(described_class.call(ai_run: image_run)).to be_a_success
  end
end
