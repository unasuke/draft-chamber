# frozen_string_literal: true

module Datatracker
  module Resources
    class Session < Base
      def for_meeting(meeting_number, params = {})
        list(params.merge(meeting__number: meeting_number))
      end

      def for_group(group_acronym, params = {})
        list(params.merge(group__acronym: group_acronym))
      end

      def for_meeting_and_group(meeting_number, group_acronym, params = {})
        list(params.merge(
          meeting__number: meeting_number,
          group__acronym: group_acronym
        ))
      end

      private

      def endpoint
        "/api/v1/meeting/session/"
      end
    end
  end
end
