class ApplicationController < ActionController::Base

	before_action :configure_permitted_parameters, if: :devise_controller?


	def configure_permitted_parameters
	  devise_parameter_sanitizer.permit(:sign_up) do |user_params|
	    user_params.permit({ roles: [] }, :email, :password, :password_confirmation, :first_name, :last_name)
	  end

	   devise_parameter_sanitizer.permit(:account_update) { |u| u.permit(:email, :password, :password_confirmation, :current_password, :first_name, :last_name)}

	end

end
