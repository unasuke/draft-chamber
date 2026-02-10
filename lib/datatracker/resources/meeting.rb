# frozen_string_literal: true

module Datatracker
  module Resources
    class Meeting < Base
      def find_by_number(number)
        response = list(number: number)
        objects = response.objects
        objects.first if objects.any?
      end

      def ietf_meetings(params = {})
        list(params.merge(type: "ietf"))
      end

      def interim_meetings(params = {})
        list(params.merge(type: "interim"))
      end

      def recent(limit: 10)
        list(limit: limit, order_by: "-date")
      end

      private

      def endpoint
        "/api/v1/meeting/meeting/"
      end
    end
  end
end
