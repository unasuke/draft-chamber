# frozen_string_literal: true

Sentry.init do |config|
  config.dsn = Rails.application.credentials.sentry_dsn
  config.breadcrumbs_logger = [ :active_support_logger, :http_logger ]
  config.send_default_pii = false
  config.enabled_patches = [ :http, :faraday ]
end
