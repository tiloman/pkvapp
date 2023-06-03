source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.0.2'
gem 'rails', '~> 6.0.3'
gem 'pg', '>= 0.18', '< 2.0'
gem 'puma', '~> 3.11'
gem 'sass-rails', '~> 5.0'
gem 'uglifier', '>= 1.3.0'
gem 'turbolinks', '~> 5'
gem 'jbuilder', '~> 2.5'
gem 'bootsnap', '>= 1.1.0', require: false

# custom
gem 'devise'
gem 'simple_form'
gem 'image_processing'
gem 'webpacker'
gem 'best_in_place', '~> 3.0.1'
gem 'simple-form-datepicker'
gem 'aasm'
gem 'aws-sdk-s3'
gem "select2-rails"
gem 'fullcalendar-rails'
gem 'momentjs-rails'
gem 'icalendar', '~> 2.6' # for webcal
gem 'filterrific'
gem 'will_paginate'
gem 'will_paginate-bootstrap4'
gem 'delayed_job_active_record'
gem "delayed_job_web"
gem "sentry-ruby"
gem 'sentry-rails'
gem 'todoist-ruby'
gem "interactor"

# mimemagic version bug...
gem 'mimemagic', github: 'mimemagicrb/mimemagic', ref: '01f92d86d15d85cfd0f20dabd025dcbd36a8a60f'

group :development, :test do
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'rspec-rails', '~> 5.0.0'
  gem 'rubocop'
  gem 'factory_bot_rails'
end

group :development do
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '>= 3.0.5', '< 3.2'
end

group :test do
  gem 'capybara', '>= 2.15'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
