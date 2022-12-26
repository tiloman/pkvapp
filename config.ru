if Rails.env.production?
  DelayedJobWeb.use Rack::Auth::Basic do |username, password|
    ActiveSupport::SecurityUtils.secure_compare('username', username) &&
      ActiveSupport::SecurityUtils.secure_compare('password', password)
  end
end

require_relative 'config/environment'

run Rails.application
