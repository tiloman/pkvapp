class BuildOperationProposal
  include Interactor

  MAX_TITLE_LENGTH = 100
  LOW_CONFIDENCE = 0.7

  def self.low_confidence_fields(run)
    ExtractBill::FIELDS.keys.select do |field|
      run.field_value(field).present? && run.field_confidence(field).to_f < LOW_CONFIDENCE
    end
  end

  # Fills context.attributes (Operation attributes) and context.warnings.
  def call
    @run = context.ai_run
    @people = @run.user.people.to_a
    context.warnings = []

    billing_date = parse_date(@run.field_value(:invoice_date))
    context.attributes = {
      title: title,
      value: amount,
      billing_date: billing_date,
      bill_deadline: deadline(billing_date),
      person_id: matched_person&.id
    }.compact

    warn_about_document_type
    warn_about_confidence
  end

  private

  def title
    text = [@run.field_value(:issuer), @run.field_value(:summary)].map { |v| v.to_s.strip }.reject(&:empty?).join(': ')
    text.truncate(MAX_TITLE_LENGTH).presence
  end

  def amount
    value = @run.field_value(:total_amount)
    return unless value.is_a?(Numeric) && value.positive?

    value.round(2)
  end

  def deadline(billing_date)
    explicit = parse_date(@run.field_value(:due_date))
    return explicit if explicit

    days = @run.field_value(:payment_terms_days)
    billing_date + days.days if billing_date && days.is_a?(Integer) && days.positive?
  end

  def parse_date(value)
    Date.iso8601(value.to_s).in_time_zone
  rescue ArgumentError
    nil
  end

  # Only unambiguous matches count: a wrong person is worse than none.
  def matched_person
    return @matched_person if defined?(@matched_person)

    @matched_person = unique_match(:equal?) || unique_match(:overlap?)
  end

  def unique_match(strategy)
    patient = tokens(@run.field_value(:patient_name))
    return if patient.empty?

    matches = @people.select do |person|
      own = tokens(person.name)
      next false if own.empty?

      strategy == :equal? ? own == patient : (own.subset?(patient) || patient.subset?(own))
    end
    matches.first if matches.one?
  end

  def tokens(name)
    I18n.transliterate(name.to_s).downcase.scan(/[a-z]+/).reject { |t| %w[dr prof med herr frau].include?(t) }.to_set
  end

  def warn_about_document_type
    case @run.field_value(:document_type)
    when 'reminder' then context.warnings << 'Das Dokument sieht wie eine Mahnung aus, nicht wie eine Rechnung.'
    when 'other' then context.warnings << 'Das Dokument wurde nicht als Rechnung erkannt.'
    end
  end

  def warn_about_confidence
    low = BuildOperationProposal.low_confidence_fields(@run)
    context.warnings << "Unsichere Felder: #{low.join(', ')}" if low.any?
  end
end
