# frozen_string_literal: true

module Datatracker
  module Resources
    class Base
      attr_reader :client

      def initialize(client)
        @client = client
      end

      def list(params = {})
        response = client.get(endpoint, params)
        handle_response(response)
      end

      def find(id)
        response = client.get("#{endpoint}#{id}/")
        handle_response(response)
      end

      def all(params = {})
        list(params.merge(limit: 0))
      end

      private

      def endpoint
        raise NotImplementedError, "Subclass must implement #endpoint"
      end

      def handle_response(response)
        case response.status
        when 200..299
          Response.new(response)
        when 400
          raise BadRequestError.new(response: response)
        when 403
          raise ForbiddenError.new(response: response)
        when 404
          raise NotFoundError.new(response: response)
        when 429
          raise RateLimitError.new(response: response)
        when 500..599
          raise ServerError.new(response: response)
        else
          raise APIError.new(response: response)
        end
      end
    end
  end
end
