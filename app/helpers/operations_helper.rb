module OperationsHelper
  def show_bill_preview(operation)
    if operation.bill.attached?
      if operation.bill.variable?
        image_tag operation.bill.variant(resize_to_limit: [300, 300]), class: 'attachment_preview'
      elsif operation.bill.previewable?
        image_tag operation.bill.preview(resize_to_limit: [300, 300]), class: 'attachment_preview'
      else
        link_to 'Rechnung',
                Rails.application.routes.url_helpers.rails_blob_path(operation.bill, disposition: 'attachment')
      end
    end
  end

  def show_insurance_notice_preview(operation)
    if operation.insurance_notice.attached?
      if operation.insurance_notice.variable?
        image_tag operation.insurance_notice.variant(resize_to_limit: [300, 300]), class: 'attachment_preview'
      elsif operation.insurance_notice.previewable?
        image_tag operation.insurance_notice.preview(resize_to_limit: [300, 300]), class: 'attachment_preview'
      else
        "Versicherungsantwort"
      end
    end
  end

  def get_overall_value(operation)
    number_to_currency(operation.value - operation.insurance_payback.to_f - operation.assistance_payback.to_f).html_safe
  end

  def get_insurance_ratio(operation)
    person = operation.person
    if person.ratio == '80/20'
      "<span id='insurance_ratio'>20</span>%: <span id='insurance_calculated'>#{number_to_currency(operation.value * 0.2)}</span>".html_safe
    elsif person.ratio == '50/50'
      "<span id='insurance_ratio'>50</span>%: <span id='insurance_calculated'>#{number_to_currency(operation.value * 0.5)}</span>".html_safe
    end
  end

  def get_assistance_ratio(operation)
    person = operation.person
    if person.ratio == '80/20'
      "<span id='assistance_ratio'>80</span>%: <span id='assistance_calculated'>#{number_to_currency((operation.value * 0.8))}</span>".html_safe
    elsif person.ratio == '50/50'
      "<span id='assistance_ratio'>50</span>%: <span id='assistance_calculated'>#{number_to_currency((operation.value * 0.5))}</span>".html_safe
    end
  end

  def get_insurance_difference(operation)
    person = operation.person
    if operation.insurance_payback.present?
      if person.ratio == '80/20'
        "Differenz: <span id='insurance_difference'>#{number_to_currency((operation.insurance_payback.to_f - (operation.value * 0.2)))}</span>".html_safe
      elsif person.ratio == '50/50'
        "Differenz: <span id='insurance_difference'>#{number_to_currency((operation.insurance_payback.to_f - (operation.value * 0.5)))}</span>".html_safe
      end
    end
  end

  def get_assistance_difference(operation)
    person = operation.person
    if operation.insurance_payback.present?
      if person.ratio == '80/20'
        "Differenz: <span id='assistance_difference'>#{number_to_currency((operation.assistance_payback.to_f - (operation.value * 0.8)))}</span> €".html_safe
      elsif person.ratio == '50/50'
        "Differenz: <span id='assistance_difference'>#{number_to_currency((operation.assistance_payback.to_f - (operation.value * 0.5)))}</span> €".html_safe
      end
    end
  end

  def show_attachment_icon(operation)
    "<i class='fas fa-paperclip'></i>".html_safe if operation.has_attachments?
  end

  def get_status_name(operation)
    case operation.aasm_state
    when 'editing'
      "<span class='badge bg-primary'>Bearbeitung</span>".html_safe
    when 'open'
      "<span class='badge bg-danger'>Noch Bearbeiten</span>".html_safe
    when 'closed'
      "<span class='badge bg-success'>Abgeschlossen</span>".html_safe
    when 'waiting'
      "<span class='badge bg-secondary'>Warten</span>".html_safe

    end
  end
end
