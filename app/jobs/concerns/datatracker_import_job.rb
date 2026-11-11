# frozen_string_literal: true

module DatatrackerImportJob
  extend ActiveSupport::Concern

  RATE_LIMIT_MAX_ATTEMPTS = 3
  RATE_LIMIT_BASE_WAIT = 5.minutes
  RATE_LIMIT_EXECUTIONS_KEY = "[Datatracker::RateLimitError]"

  included do
    queue_as :default

    limits_concurrency to: 1, key: "datatracker_api_sync", duration: 1.hour

    retry_on Datatracker::ServerError, wait: 30.seconds, attempts: 3
    retry_on Faraday::TimeoutError, wait: 1.minute, attempts: 3
    retry_on Faraday::ConnectionFailed, wait: 1.minute, attempts: 3
    retry_on Datatracker::ThrottleError, wait: 1.minute, attempts: 3

    # Count only 429s, since executions also includes retries for other errors
    rescue_from Datatracker::RateLimitError do |error|
      count = (exception_executions[RATE_LIMIT_EXECUTIONS_KEY] || 0) + 1
      exception_executions[RATE_LIMIT_EXECUTIONS_KEY] = count

      raise error if count >= RATE_LIMIT_MAX_ATTEMPTS

      wait = [ error.retry_after, (RATE_LIMIT_BASE_WAIT * count).to_i ].compact.max
      Rails.logger.warn("[DatatrackerAPI] Rate limited, retrying in #{wait}s (attempt #{count})")
      retry_job(wait: wait)
    end

    around_perform :report_api_error_details
  end

  private

  def report_api_error_details
    yield
  rescue Datatracker::APIError => e
    if e.response
      Rails.logger.error(
        "[DatatrackerAPI] #{e.message} - " \
        "Response headers: #{e.response.headers.to_h} - " \
        "Response body: #{e.response.body}"
      )

      Sentry.set_context("datatracker_response", {
        status: e.status,
        headers: e.response.headers.to_h,
        body: e.response.body.to_s.truncate(1000)
      })
    end
    raise
  end
end
