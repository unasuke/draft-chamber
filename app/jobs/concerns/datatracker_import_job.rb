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
