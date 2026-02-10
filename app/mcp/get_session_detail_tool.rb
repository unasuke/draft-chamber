# frozen_string_literal: true

class GetSessionDetailTool < MCP::Tool
  description "Get detailed information about a session including its presentations and documents"

  input_schema(
    properties: {
      session_id: {
        type: "integer",
        description: "Datatracker session ID"
      }
    },
    required: [ "session_id" ]
  )

  class << self
    def call(server_context:, **params)
      session = Session.includes(:meeting, :group, session_presentations: :document)
                       .find_by(datatracker_id: params[:session_id])

      unless session
        return MCP::Tool::Response.new(
          [ { type: "text", text: "Session with ID #{params[:session_id]} not found" } ],
          error: true
        )
      end

      result = {
        id: session.datatracker_id,
        name: session.name,
        meeting_number: session.meeting.number,
        group: session.group&.acronym,
        group_name: session.group&.name,
        purpose: session.purpose,
        requested_duration: session.requested_duration,
        on_agenda: session.on_agenda,
        attendees: session.attendees,
        remote_instructions: session.remote_instructions,
        presentations: session.session_presentations.ordered.map { |sp| presentation_to_hash(sp) }
      }

      MCP::Tool::Response.new([ {
        type: "text",
        text: JSON.generate(result)
      } ])
    end

    private

    def presentation_to_hash(session_presentation)
      doc = session_presentation.document
      {
        order: session_presentation.order,
        rev: session_presentation.rev,
        document: {
          name: doc.name,
          title: doc.title,
          type: doc.document_type,
          rev: doc.rev,
          pages: doc.pages
        }
      }
    end
  end
end
