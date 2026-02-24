# frozen_string_literal: true

module DatatrackerImportJob
  extend ActiveSupport::Concern

  included do
    queue_as :default

    limits_concurrency to: 1, key: "datatracker_api_sync", duration: 5.minutes

    retry_on Datatracker::RateLimitError, wait: :polynomially_longer, attempts: 3
    retry_on Datatracker::ServerError, wait: 30.seconds, attempts: 3
    retry_on Faraday::TimeoutError, wait: 1.minute, attempts: 3
    retry_on Faraday::ConnectionFailed, wait: 1.minute, attempts: 3
  end
end
