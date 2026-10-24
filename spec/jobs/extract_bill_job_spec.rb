require 'rails_helper'
require_relative '../interactors/ai_run_helpers'

RSpec.describe ExtractBillJob do
  let(:user) { FactoryBot.create(:user) }
  let(:run) { create_run(user, status: 'processing', output: {}) }

  it 'uses its own queue so a dedicated worker can pick it up' do
    expect(described_class.new.queue_name).to eq('ai')
  end

  it 'runs the extraction for processing runs' do
    expect(ExtractBill).to receive(:call).with(ai_run: run)
    described_class.perform_now(run.id)
  end

  it 'ignores runs that are not processing or no longer exist' do
    expect(ExtractBill).not_to receive(:call)
    described_class.perform_now(create_run(user, status: 'proposed').id)
    described_class.perform_now(0)
  end

  it 'retries on rate limit errors while attempts remain' do
    allow(ExtractBill).to receive(:call).and_raise(AiClient::RateLimitError)
    expect { described_class.perform_now(run.id) }.to have_enqueued_job(described_class)
    expect(run.reload).to be_processing
  end

  it 'marks the run failed once rate limit retries are exhausted' do
    allow(ExtractBill).to receive(:call).and_raise(AiClient::RateLimitError)
    job = described_class.new(run.id)
    job.exception_executions = { '[AiClient::RateLimitError]' => 2 }

    expect { job.perform_now }.not_to have_enqueued_job(described_class)
    expect(run.reload).to be_failed
    expect(run.error_message).to include('Rate-Limit')
  end
end
