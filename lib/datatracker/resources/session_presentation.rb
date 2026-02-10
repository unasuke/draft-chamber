# frozen_string_literal: true

module Datatracker
  module Resources
    class SessionPresentation < Base
      def for_session(session_id, params = {})
        list(params.merge(session: session_id))
      end

      def for_meeting_and_group(meeting_number, group_acronym, params = {})
        list(params.merge(
          session__meeting__number: meeting_number,
          session__group__acronym: group_acronym
        ))
      end

      def all_for_meeting_and_group(meeting_number, group_acronym)
        for_meeting_and_group(meeting_number, group_acronym, limit: 0)
      end

      private

      def endpoint
        "/api/v1/meeting/sessionpresentation/"
      end
    end
  end
end
