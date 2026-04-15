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

  output_schema(
    type: "object",
    properties: {
      number: { type: "string" },
      type: { type: "string" },
      date: { type: "string" },
      city: { type: "string" },
      country: { type: "string" },
      venue_name: { type: "string" },
      time_zone: { type: "string" },
      days: { type: "integer" },
      attendees: { type: "integer" },
      sessions: {
        type: "array",
        items: {
          type: "object",
          properties: {
            id: { type: "integer" },
            name: { type: "string" },
            group: { type: "string" },
            purpose: { type: "string" },
            requested_duration: { type: "integer" },
            on_agenda: { type: "boolean" }
          },
          required: [ "id" ]
        }
      }
    },
    required: [ "number", "type", "sessions" ]
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

      data = {
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

      MCP::Tool::Response.new(
        [ { type: "text", text: JSON.generate(data) } ],
        structured_content: data
      )
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
