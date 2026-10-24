class ExtractBillJob < ApplicationJob
  # Own queue so a dedicated worker can run it without touching the legacy default queue.
  queue_as :ai

  retry_on AiClient::RateLimitError, wait: 30.seconds, attempts: 3 do |job, _error|
    run = AiRun.find_by(id: job.arguments.first)
    run&.transition_to!('failed', error_message: 'Das Rate-Limit des KI-Anbieters wurde erreicht. Bitte später erneut versuchen.')
  end

  def perform(ai_run_id)
    run = AiRun.find_by(id: ai_run_id)
    return unless run&.processing?

    ExtractBill.call(ai_run: run)
  end
end
