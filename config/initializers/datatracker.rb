# frozen_string_literal: true

Rails.application.config.after_initialize do
  Datatracker.configure do |config|
    # Share the request interval across Solid Queue worker processes
    config.throttle_store = Rails.cache
    config.logger = Rails.logger
  end
end
