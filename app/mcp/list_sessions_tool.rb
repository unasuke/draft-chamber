# frozen_string_literal: true

class ListSessionsTool < MCP::Tool
  description "List sessions for a specific IETF meeting, optionally filtered by working group"

  input_schema(
    properties: {
      meeting_number: {
        type: "string",
        description: "Meeting number (e.g. '124')"
      },
      group_acronym: {
        type: "string",
        description: "Filter by working group acronym (e.g. 'tls')"
      }
    },
    required: [ "meeting_number" ]
  )

  class << self
    def call(server_context:, **params)
      meeting = Meeting.find_by(number: params[:meeting_number])

      unless meeting
        return MCP::Tool::Response.new(
          [ { type: "text", text: "Meeting '#{params[:meeting_number]}' not found" } ],
          error: true
        )
      end

      sessions = meeting.sessions.includes(:group)
      if params[:group_acronym]
        sessions = sessions.joins(:group).where(groups: { acronym: params[:group_acronym] })
      end

      result = sessions.map { |s| session_to_hash(s) }

      MCP::Tool::Response.new([ {
        type: "text",
        text: JSON.generate(result)
      } ])
    end

    private

    def session_to_hash(session)
      {
        id: session.datatracker_id,
        name: session.name,
        group: session.group&.acronym,
        group_name: session.group&.name,
        purpose: session.purpose,
        requested_duration: session.requested_duration,
        on_agenda: session.on_agenda,
        attendees: session.attendees,
        remote_instructions: session.remote_instructions
      }
    end
  end
end
