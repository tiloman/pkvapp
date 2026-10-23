module AiRunHelpers
  def field(value, confidence = 0.95, evidence = 'Beleg')
    { 'value' => value, 'confidence' => confidence, 'evidence' => evidence }
  end

  def bill_output(overrides = {})
    {
      'issuer' => field('Dr. Müller Zahnarztpraxis'),
      'patient_name' => field('Hanna Lohmann'),
      'invoice_date' => field('2026-10-01'),
      'due_date' => field(nil),
      'payment_terms_days' => field(30),
      'total_amount' => field(123.456),
      'summary' => field('Professionelle Zahnreinigung'),
      'document_type' => field('bill')
    }.merge(overrides)
  end

  def create_run(user, status: 'proposed', output: bill_output, operation: nil, provider: 'claude')
    run = AiRun.new(user: user, kind: 'extract_bill', status: status, output: output, operation: operation,
                    provider: provider)
    run.document.attach(io: StringIO.new('%PDF-1.4'), filename: 'rechnung.pdf', content_type: 'application/pdf')
    run.save!
    run
  end
end

RSpec.configure { |config| config.include AiRunHelpers }
