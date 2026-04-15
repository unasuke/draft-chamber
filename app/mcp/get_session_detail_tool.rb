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

  output_schema(
    type: "object",
    properties: {
      id: { type: "integer" },
      name: { type: "string" },
      meeting_number: { type: "string" },
      group: { type: "string" },
      group_name: { type: "string" },
      purpose: { type: "string" },
      requested_duration: { type: "string" },
      on_agenda: { type: "boolean" },
      attendees: { type: "integer" },
      remote_instructions: { type: "string" },
      presentations: {
        type: "array",
        items: {
          type: "object",
          properties: {
            order: { type: "integer" },
            rev: { type: "string" },
            document: {
              type: "object",
              properties: {
                name: { type: "string" },
                title: { type: "string" },
                type: { type: "string" },
                rev: { type: "string" },
                pages: { type: "integer" }
              },
              required: [ "name" ]
            }
          },
          required: [ "order", "document" ]
        }
      }
    },
    required: [ "id", "presentations" ]
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

      data = {
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

      MCP::Tool::Response.new(
        [ { type: "text", text: JSON.generate(data) } ],
        structured_content: data
      )
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
