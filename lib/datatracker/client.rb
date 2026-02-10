# frozen_string_literal: true

module Datatracker
  class Client
    attr_reader :config, :connection

    def initialize(config = nil)
      @config = config || Datatracker.configuration
      @connection = build_connection
    end

    def groups
      Resources::Group.new(self)
    end

    def meetings
      Resources::Meeting.new(self)
    end

    def sessions
      Resources::Session.new(self)
    end

    def session_presentations
      Resources::SessionPresentation.new(self)
    end

    def documents
      Resources::Document.new(self)
    end

    def get(path, params = {})
      connection.get(path, params)
    end

    private

    def build_connection
      Faraday.new(url: config.base_url) do |faraday|
        faraday.request :json
        faraday.response :json
        faraday.request :retry, config.retry_options
        faraday.options.timeout = config.timeout
        faraday.options.open_timeout = config.open_timeout
        faraday.adapter Faraday.default_adapter
      end
    end
  end
end
