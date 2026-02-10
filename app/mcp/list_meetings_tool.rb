# frozen_string_literal: true

class ListMeetingsTool < MCP::Tool
  description "List available IETF meetings sorted by date (newest first)"

  input_schema(
    properties: {
      meeting_type: {
        type: "string",
        enum: %w[ietf interim],
        description: "Filter by meeting type (ietf or interim)"
      },
      limit: {
        type: "integer",
        description: "Maximum number of meetings to return (default: 20)"
      }
    }
  )

  class << self
    def call(server_context:, **params)
      meetings = Meeting.recent
      meetings = meetings.where(meeting_type: params[:meeting_type]) if params[:meeting_type]
      meetings = meetings.limit(params[:limit] || 20)

      result = meetings.map { |m| meeting_to_hash(m) }

      MCP::Tool::Response.new([ {
        type: "text",
        text: JSON.generate(result)
      } ])
    end

    private

    def meeting_to_hash(meeting)
      {
        number: meeting.number,
        type: meeting.meeting_type,
        date: meeting.date&.iso8601,
        city: meeting.city,
        country: meeting.country,
        venue_name: meeting.venue_name,
        days: meeting.days,
        attendees: meeting.attendees
      }
    end
  end
end
