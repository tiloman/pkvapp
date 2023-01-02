Sentry.init do |config|
  config.dsn = "https://7ac5b1466b3745179769cf2c33f98c31@o1217310.ingest.sentry.io/4504434131992576"
  config.breadcrumbs_logger = %i[active_support_logger http_logger]
  config.traces_sample_rate = 0
  config.enabled_environments = %w[production staging]
end
