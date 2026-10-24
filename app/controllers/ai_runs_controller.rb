class AiRunsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_integration, only: %i[new create retry]
  before_action :set_run, only: %i[show update reject revert retry]

  def index
    @ai_runs = current_user.ai_runs.includes(:operation).order(created_at: :desc).limit(50)
  end

  def new
    @operation = source_operation
    @run = current_user.ai_runs.build
  end

  def create
    @operation = source_operation
    return render_new_with('Bitte bestätige die Einwilligung zur Datenübermittlung.') unless consent_given?

    if @operation && !bill_file_present?(@operation)
      return render_new_with('Die Rechnungsdatei dieses Vorgangs fehlt im Speicher. Bitte lade sie neu hoch.')
    end

    @run = build_run(provider: selected_provider(params[:provider]), operation: @operation,
                     blob: @operation&.bill&.blob, upload: params.dig(:ai_run, :document))
    if @run.save
      current_user.update_column(:ai_consented_at, Time.current) unless current_user.ai_consented?
      ExtractBillJob.perform_later(@run.id)
      redirect_to @run
    else
      render_new_with(@run.errors.full_messages.to_sentence)
    end
  end

  def show
    return unless @run.proposed?

    @operation = @run.operation || Operation.new
    proposal = BuildOperationProposal.call(ai_run: @run)
    @operation.assign_attributes(proposal.attributes)
    @warnings = proposal.warnings
  end

  def update
    result = ApplyAiRun.call(ai_run: @run, attributes: operation_params)
    if result.success?
      redirect_to result.operation, notice: 'Vorgang wurde aus der Rechnung übernommen.'
    else
      @operation = result.operation || Operation.new(operation_params)
      @warnings = []
      flash.now[:alert] = result.error
      render :show, status: :unprocessable_entity
    end
  end

  def reject
    @run.transition_to!('rejected') if @run.proposed? || @run.failed? || @run.stale?
    redirect_to dashboard_path, notice: 'Vorschlag wurde verworfen.'
  end

  def revert
    result = RevertAiRun.call(ai_run: @run)
    if result.success?
      notice = 'Übernahme wurde rückgängig gemacht.'
      notice += " Nicht zurückgesetzt, weil inzwischen geändert: #{result.skipped.join(', ')}." if result.skipped.present?
      redirect_to(@run.operation || ai_run_path(@run), notice: notice)
    else
      redirect_to ai_run_path(@run), alert: result.error
    end
  end

  # Re-analyses the same document, e.g. with the other provider.
  def retry
    return redirect_to(@run, alert: 'Dieser Vorschlag ist bereits entschieden.') if @run.decided? || (@run.processing? && !@run.stale?)

    new_run = build_run(provider: selected_provider(params[:provider]), operation: @run.operation,
                        blob: @run.document.blob)
    AiRun.transaction do
      new_run.save!
      @run.transition_to!('rejected')
    end
    ExtractBillJob.perform_later(new_run.id)
    redirect_to new_run
  end

  private

  def set_run
    @run = current_user.ai_runs.find(params[:id])
  end

  def require_integration
    return if current_user.ai_enabled?

    redirect_to integrations_path, alert: 'Verbinde zuerst einen KI-Anbieter.'
  end

  # An existing operation whose bill should be read; always scoped to the user's own people.
  def source_operation
    return if params[:operation_id].blank?

    Operation.where(person_id: current_user.people.select(:id)).find(params[:operation_id])
  end

  def bill_file_present?(operation)
    operation.bill.attached? && operation.bill.service.exist?(operation.bill.key)
  end

  def consent_given?
    current_user.ai_consented? || params[:consent] == '1'
  end

  def selected_provider(requested)
    providers = current_user.ai_providers
    providers.include?(requested) ? requested : providers.first
  end

  def build_run(provider:, operation:, blob: nil, upload: nil)
    run = current_user.ai_runs.build(kind: 'extract_bill', provider: provider, operation: operation)
    document = blob || upload
    run.document.attach(document) if document
    run
  end

  def render_new_with(message)
    @run ||= current_user.ai_runs.build
    flash.now[:alert] = message
    render :new, status: :unprocessable_entity
  end

  def operation_params
    params.require(:operation).permit(:title, :value, :billing_date, :bill_deadline, :person_id)
  end
end
