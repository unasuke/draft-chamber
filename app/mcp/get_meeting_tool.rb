# frozen_string_literal: true

class GetMeetingTool < MCP::Tool
  description "Get details of a specific IETF meeting by number, including its sessions"

  input_schema(
    properties: {
      number: {
        type: "string",
        description: "Meeting number (e.g. '124' or 'interim-2025-tls-01')"
      }
    },
    required: [ "number" ]
  )

  class << self
    def call(server_context:, **params)
      meeting = Meeting.includes(sessions: :group).find_by(number: params[:number])

      unless meeting
        return MCP::Tool::Response.new(
          [ { type: "text", text: "Meeting '#{params[:number]}' not found" } ],
          error: true
        )
      end

      result = {
        number: meeting.number,
        type: meeting.meeting_type,
        date: meeting.date&.iso8601,
        city: meeting.city,
        country: meeting.country,
        venue_name: meeting.venue_name,
        time_zone: meeting.time_zone,
        days: meeting.days,
        attendees: meeting.attendees,
        sessions: meeting.sessions.map { |s| session_summary(s) }
      }

      MCP::Tool::Response.new([ {
        type: "text",
        text: JSON.generate(result)
      } ])
    end

    private

    def session_summary(session)
      {
        id: session.datatracker_id,
        name: session.name,
        group: session.group&.acronym,
        purpose: session.purpose,
        requested_duration: session.requested_duration,
        on_agenda: session.on_agenda
      }
    end
  end
end
