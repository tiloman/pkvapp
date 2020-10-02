module ApplicationHelper

	def check_icons(value, text)

			description = "<span class='check_text'>#{text}</span><br>" if text.present?  

		if value == true
			return "<div>#{description if text}<i class='fas fa-check' style='color: green'></i></div>".html_safe
		else
			return "<div>#{description if text}<i class='fas fa-times' style='color: red'></i></div>".html_safe
		end 
	end 

end
