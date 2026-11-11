# frozen_string_literal: true

module Datatracker
  class Error < StandardError; end

  class ThrottleError < Error; end

  class APIError < Error
    attr_reader :response, :status

    def initialize(message = nil, response: nil)
      @response = response
      @status = response&.status
      super(message || default_message)
    end

    private

    def default_message
      "API request failed with status #{status}"
    end
  end

  class NotFoundError < APIError
    private

    def default_message
      "Resource not found (404)"
    end
  end

  class BadRequestError < APIError
    private

    def default_message
      "Bad request (400)"
    end
  end

  class ServerError < APIError
    private

    def default_message
      "Server error (#{status})"
    end
  end

  class ForbiddenError < APIError
    private

    def default_message
      "Forbidden (403)"
    end
  end

  class RateLimitError < APIError
    # Seconds to wait as instructed by the Retry-After header, or nil when absent or unparseable
    def retry_after
      value = response&.headers&.[]("retry-after").to_s.strip
      return nil if value.empty?
      return value.to_i if value.match?(/\A\d+\z/)

      [ (Time.httpdate(value) - Time.now).ceil, 0 ].max
    rescue ArgumentError
      nil
    end

    private

    def default_message
      "Rate limit exceeded (429)"
    end
  end
end
