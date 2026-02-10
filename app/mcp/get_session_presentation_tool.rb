# frozen_string_literal: true

class GetSessionPresentationTool < MCP::Tool
  description "Get details of a specific session presentation including its document and material URL"

  input_schema(
    properties: {
      document_name: {
        type: "string",
        description: "Document name (e.g. 'slides-124-tls-chairs-slides')"
      }
    },
    required: %w[document_name]
  )

  class << self
    def call(server_context:, **params)
      document = Document.find_by(name: params[:document_name])
      unless document
        return error_response("Document '#{params[:document_name]}' not found")
      end

      presentations = SessionPresentation
        .includes(session: [ :meeting, :group ], document: { document_material: { file_attachment: :blob } })
        .where(document: document)
        .ordered

      if presentations.empty?
        return error_response("No presentation found for document '#{params[:document_name]}'")
      end

      result = presentations.map { |sp| presentation_to_hash(sp, document) }

      MCP::Tool::Response.new([ {
        type: "text",
        text: JSON.generate(result)
      } ])
    end

    private

    def error_response(message)
      MCP::Tool::Response.new(
        [ { type: "text", text: message } ],
        error: true
      )
    end

    def presentation_to_hash(presentation, document)
      meeting = presentation.session.meeting
      {
        order: presentation.order,
        rev: presentation.rev,
        session: {
          id: presentation.session.datatracker_id,
          name: presentation.session.name,
          group: presentation.session.group&.acronym,
          meeting_number: meeting.number
        },
        document: {
          name: document.name,
          title: document.title,
          type: document.document_type,
          rev: document.rev,
          pages: document.pages,
          abstract: document.abstract,
          uploaded_filename: document.uploaded_filename,
          file_available: document.material_attached?,
          file_download_status: document.document_material&.download_status
        },
        material_url: "https://datatracker.ietf.org/meeting/#{meeting.number}/materials/#{document.name}/"
      }
    end
  end
end
