# frozen_string_literal: true

module Datatracker
  class Configuration
    attr_accessor :base_url, :timeout, :open_timeout, :retry_options

    def initialize
      @base_url = "https://datatracker.ietf.org"
      @timeout = 30
      @open_timeout = 10
      @retry_options = {
        max: 2,
        interval: 0.5,
        backoff_factor: 2,
        exceptions: [Faraday::TimeoutError, Faraday::ConnectionFailed]
      }
    end
  end
end
