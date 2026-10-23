class ApplyAiRun
  include Interactor

  PERMITTED = %w[title value billing_date bill_deadline person_id].freeze
  REQUIRED = %i[value bill_deadline].freeze

  # context.ai_run, context.attributes (reviewed by the user). Creates the operation for a
  # run without one, otherwise updates the existing operation.
  def call
    run = context.ai_run
    context.fail!(error: 'Der Vorschlag wurde bereits entschieden.') unless run.proposed?

    attributes = permitted_attributes
    person_id = attributes['person_id']
    if person_id.present? && !run.user.people.exists?(id: person_id)
      context.fail!(error: 'Die Person gehört nicht zu diesem Konto.')
    end

    created = run.operation.nil?
    operation = run.operation || Operation.new
    operation.assign_attributes(attributes)
    context.operation = operation

    AiRun.transaction do
      context.fail!(error: operation.errors.full_messages.to_sentence) unless valid_for_display?(operation) && operation.save
      applied = changes(operation, created) # attach saves again and would clear saved_changes
      operation.bill.attach(run.document.blob) if created || !operation.bill.attached?
      run.transition_to!('accepted', operation: operation, applied_changes: applied)
    end
    SyncTodoist.call(operation: operation)
  end

  private

  # The operation pages calculate with value and bill_deadline, so both must be present.
  def valid_for_display?(operation)
    operation.validate
    REQUIRED.each { |attribute| operation.errors.add(attribute, :blank) if operation[attribute].blank? }
    operation.errors.empty?
  end

  # Keeps multiparameter date keys like "bill_deadline(1i)" of date_select inputs.
  def permitted_attributes
    context.attributes.to_h.stringify_keys.select { |key, _| PERMITTED.include?(key.sub(/\(\di\)\z/, '')) }
  end

  def changes(operation, created)
    changed = operation.saved_changes.slice(*PERMITTED).transform_values { |(from, to)| [serialize(from), serialize(to)] }
    created ? changed.merge('_created' => true) : changed
  end

  def serialize(value)
    value.respond_to?(:iso8601) ? value.iso8601 : value
  end
end
