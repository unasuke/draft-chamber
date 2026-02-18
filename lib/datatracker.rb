# frozen_string_literal: true

require "faraday"
require "faraday/retry"

require_relative "datatracker/configuration"
require_relative "datatracker/error"
require_relative "datatracker/response"
require_relative "datatracker/client"
require_relative "datatracker/resources/base"
require_relative "datatracker/resources/group"
require_relative "datatracker/resources/meeting"
require_relative "datatracker/resources/session"
require_relative "datatracker/resources/session_presentation"
require_relative "datatracker/resources/document"

module Datatracker
  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end
