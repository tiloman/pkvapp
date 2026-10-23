class RevertAiRun
  include Interactor

  GRACE = 2.seconds

  # Undoes an accepted run: deletes an operation the run created (if untouched since),
  # or restores the fields it changed (only those still holding the AI value).
  def call
    run = context.ai_run
    context.fail!(error: 'Nur übernommene Vorschläge können rückgängig gemacht werden.') unless run.accepted?

    operation = run.operation
    context.fail!(error: 'Der Vorgang existiert nicht mehr.') unless operation

    run.applied_changes['_created'] ? revert_creation(run, operation) : revert_update(run, operation)
  end

  private

  def revert_creation(run, operation)
    if operation.updated_at > run.decided_at + GRACE
      context.fail!(error: 'Der Vorgang wurde seit der Übernahme geändert und bleibt bestehen.')
    end

    AiRun.transaction do
      operation.destroy!
      run.reload.transition_to!('reverted')
    end
  end

  def revert_update(run, operation)
    restorable = run.applied_changes.except('_created').select do |field, (_, to)|
      serialize(operation[field]) == to
    end
    operation.assign_attributes(restorable.transform_values(&:first))

    AiRun.transaction do
      context.fail!(error: operation.errors.full_messages.to_sentence) unless operation.save
      run.transition_to!('reverted')
    end
    context.skipped = run.applied_changes.except('_created').keys - restorable.keys
  end

  def serialize(value)
    value.respond_to?(:iso8601) ? value.iso8601 : value
  end
end
