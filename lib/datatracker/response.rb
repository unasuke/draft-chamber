# frozen_string_literal: true

module Datatracker
  class Response
    attr_reader :data, :meta, :raw_response

    def initialize(raw_response)
      @raw_response = raw_response
      @data = parse_data
      @meta = parse_meta
    end

    def objects
      data["objects"] || [ data ]
    end

    def total_count
      meta["total_count"]
    end

    def limit
      meta["limit"]
    end

    def offset
      meta["offset"]
    end

    def next_page?
      meta["next"].present?
    end

    def previous_page?
      meta["previous"].present?
    end

    def next_page_url
      meta["next"]
    end

    def previous_page_url
      meta["previous"]
    end

    def success?
      raw_response.success?
    end

    def status
      raw_response.status
    end

    private

    def parse_data
      raw_response.body.is_a?(Hash) ? raw_response.body : {}
    end

    def parse_meta
      data["meta"] || {}
    end
  end
end
