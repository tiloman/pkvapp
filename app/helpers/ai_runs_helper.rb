module AiRunsHelper
  # Which extracted fields feed which operation attribute.
  FIELD_SOURCES = {
    title: %i[issuer summary],
    value: %i[total_amount],
    billing_date: %i[invoice_date],
    bill_deadline: %i[due_date payment_terms_days invoice_date],
    person_id: %i[patient_name]
  }.freeze

  def ai_run_status_badge(run)
    colors = { 'processing' => 'secondary', 'proposed' => 'warning', 'accepted' => 'success',
               'rejected' => 'secondary', 'failed' => 'danger', 'reverted' => 'dark' }
    content_tag(:span, t("ai_runs.statuses.#{run.status}"), class: "badge bg-#{colors[run.status]}")
  end

  # Confidence badge plus the quoted evidence for one operation attribute.
  def ai_field_hint(run, attribute, current_value)
    sources = FIELD_SOURCES.fetch(attribute).select { |field| run.field_value(field).present? }
    return content_tag(:span, 'Nicht erkannt', class: 'badge bg-danger') if sources.empty? || current_value.blank?

    confidence = sources.map { |field| run.field_confidence(field).to_f }.min
    evidence = sources.filter_map { |field| run.field_evidence(field).presence }.join(' · ')
    safe_join([
      content_tag(:span, "#{(confidence * 100).round} %", class: "badge bg-#{confidence_color(confidence)} me-2"),
      content_tag(:span, evidence, class: 'text-muted')
    ])
  end

  def ai_run_document_preview(run)
    path = rails_blob_path(run.document, disposition: 'inline')
    if run.document.content_type == 'application/pdf'
      content_tag(:iframe, '', src: path, class: 'w-100 border rounded', style: 'height: 75vh;')
    else
      image_tag(path, class: 'img-fluid border rounded')
    end
  end

  def ai_provider_options(user)
    user.ai_providers.map { |provider| [t("ai_integrations.providers.#{provider}"), provider] }
  end

  private

  def confidence_color(confidence)
    if confidence >= 0.9
      'success'
    elsif confidence >= BuildOperationProposal::LOW_CONFIDENCE
      'warning'
    else
      'danger'
    end
  end
end
