# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  layout 'landing'

  def edit
    render layout: 'application'
  end
end
