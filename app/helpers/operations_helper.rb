module OperationsHelper

	 def show_bill_preview(operation)
	 	if operation.bill.attached?
		 	if operation.bill.variable?
		   		image_tag operation.bill.variant(resize_to_limit: [300, 300]), class: "attachment_preview"
	   	elsif operation.bill.previewable?
	   	   	"PDF PREVIEW NA"
	   	   	#image_tag operation.bill.preview(resize_to_limit: [300, 300]), class: "attachment_preview"
	   	end
	    end
	 end

	def show_insurance_notice_preview(operation)
	 	if operation.insurance_notice.attached?
		 	if operation.insurance_notice.variable?
		   		image_tag operation.insurance_notice.variant(resize_to_limit: [300, 300]), class: "attachment_preview"
	   	elsif operation.insurance_notice.previewable?
	   	   	#"PDF PREVIEW NA"
	   	   	image_tag operation.insurance_notice.preview(resize_to_limit: [300, 300]), class: "attachment_preview"
			else
					link_to "Download", Rails.application.routes.url_helpers.rails_blob_path(operation.insurance_notice, disposition: "attachment")
			end
	    end
	 end

	def get_overall_value(operation)
		operation.value - operation.insurance_payback.to_f - operation.assistance_payback.to_f
	end

	def get_insurance_ratio(operation)
		person = operation.person
		if person.ratio == "80/20"
			return ("20%: #{(operation.value * 0.2).round(2)} €").html_safe
		elsif person.ratio == "50/50"
			return ("50%: #{(operation.value * 0.5).round(2)} €").html_safe
		end
	end

	def get_assistance_ratio(operation)
		person = operation.person
		if person.ratio == "80/20"
			return ("80%: #{(operation.value * 0.8).round(2)} €").html_safe
		elsif person.ratio == "50/50"
			return ("50%: #{(operation.value * 0.5).round(2)} €").html_safe
		end
	end

	def get_insurance_difference(operation)
		person = operation.person
		if operation.insurance_payback.present?
			if person.ratio == "80/20"
				return ("Differenz: #{(operation.insurance_payback.to_f - (operation.value * 0.2)).round(2)} €").html_safe
			elsif person.ratio == "50/50"
				return ("Differenz: #{(operation.insurance_payback.to_f - (operation.value * 0.5)).round(2)} €").html_safe
			end
		end
	end

	def get_assistance_difference(operation)
		person = operation.person
		if operation.insurance_payback.present?
			if person.ratio == "80/20"
				return ("Differenz: #{(operation.assistance_payback.to_f - (operation.value * 0.8)).round(2)} €").html_safe
			elsif person.ratio == "50/50"
				return ("Differenz: #{(operation.assistance_payback.to_f - (operation.value * 0.5)).round(2)} €").html_safe
			end
		end
	end

	def show_attachment_icon(operation)
		if operation.has_attachments?
			return ("<i class='fas fa-paperclip'></i>").html_safe
		end
	end

end
