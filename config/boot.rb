ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

# Required for ActiveSupport::LoggerSilence with Ruby 3+ / concurrent-ruby (e.g. when loading Webpacker)
require "logger"

require 'bundler/setup' # Set up gems listed in the Gemfile.
require 'bootsnap/setup' # Speed up boot time by caching expensive operations.
