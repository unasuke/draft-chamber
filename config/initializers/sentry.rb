# frozen_string_literal: true

Sentry.init do |config|
  config.dsn = Rails.application.credentials.sentry_dsn
  config.breadcrumbs_logger = [ :active_support_logger, :http_logger ]
  config.send_default_pii = false
  config.enabled_patches = [ :http, :faraday ]
  config.enabled_environments = %w[production]

  # Net::HTTP counts DNS resolution against open_timeout, and the default of 1s
  # is tight enough that a slow lookup drops the report. Losing error reports is
  # worse than a slow request here, since delivery happens on a background thread.
  config.transport.open_timeout = 5
  config.transport.timeout = 10
end
