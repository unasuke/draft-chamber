# frozen_string_literal: true

module Datatracker
  module Resources
    class Group < Base
      def find_by_acronym(acronym)
        response = list(acronym: acronym)
        objects = response.objects
        objects.first if objects.any?
      end

      def active(params = {})
        list(params.merge(state: "active"))
      end

      def working_groups(params = {})
        list(params.merge(type: "wg"))
      end

      private

      def endpoint
        "/api/v1/group/group/"
      end
    end
  end
end
