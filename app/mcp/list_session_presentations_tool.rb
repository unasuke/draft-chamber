# frozen_string_literal: true

class ListSessionPresentationsTool < MCP::Tool
  description "List session presentations for a specific meeting and working group"

  input_schema(
    properties: {
      meeting_number: {
        type: "string",
        description: "Meeting number (e.g. '124')"
      },
      group_acronym: {
        type: "string",
        description: "Working group acronym (e.g. 'tls')"
      }
    },
    required: %w[meeting_number group_acronym]
  )

  output_schema(
    type: "object",
    properties: {
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
                pages: { type: "integer" },
                file_available: { type: "boolean" },
                file_download_status: { type: "string" }
              },
              required: [ "name" ]
            }
          },
          required: [ "order", "document" ]
        }
      }
    },
    required: [ "presentations" ]
  )

  class << self
    def call(server_context:, **params)
      meeting = Meeting.find_by(number: params[:meeting_number])
      unless meeting
        return error_response("Meeting '#{params[:meeting_number]}' not found")
      end

      group = Group.find_by(acronym: params[:group_acronym])
      unless group
        return error_response("Group '#{params[:group_acronym]}' not found")
      end

      presentations = SessionPresentation
        .joins(:session)
        .includes(document: { document_material: { file_attachment: :blob } })
        .where(sessions: { meeting_id: meeting.id, group_id: group.id })
        .ordered

      data = { presentations: presentations.map { |sp| presentation_to_hash(sp) } }

      MCP::Tool::Response.new(
        [ { type: "text", text: JSON.generate(data) } ],
        structured_content: data
      )
    end

    private

    def error_response(message)
      MCP::Tool::Response.new(
        [ { type: "text", text: message } ],
        error: true
      )
    end

    def presentation_to_hash(sp)
      doc = sp.document
      {
        order: sp.order,
        rev: sp.rev,
        document: {
          name: doc.name,
          title: doc.title,
          type: doc.document_type,
          rev: doc.rev,
          pages: doc.pages,
          file_available: doc.material_attached?,
          file_download_status: doc.document_material&.download_status
        }
      }
    end
  end
end
