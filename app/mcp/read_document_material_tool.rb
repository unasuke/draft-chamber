# frozen_string_literal: true

class ReadDocumentMaterialTool < MCP::Tool
  description "Read the file content of a document material by document name. Returns text content directly or base64-encoded blob for binary files."

  input_schema(
    properties: {
      document_name: {
        type: "string",
        description: "Document name (e.g. 'slides-124-quic-qlog')"
      }
    },
    required: %w[document_name]
  )

  TEXT_CONTENT_TYPES = %w[text/plain text/html text/markdown].freeze
  IMAGE_CONTENT_TYPES = %w[image/png image/jpeg].freeze

  class << self
    def call(server_context:, **params)
      document = Document.find_by(name: params[:document_name])
      unless document
        return error_response("Document '#{params[:document_name]}' not found")
      end

      material = document.document_material
      unless material&.completed? && material.file.attached?
        return error_response("Material not available for document '#{params[:document_name]}'")
      end

      blob = material.file.blob
      content_type = blob.content_type

      content = if TEXT_CONTENT_TYPES.include?(content_type)
        [ { type: "text", text: material.file.download.force_encoding("UTF-8") } ]
      elsif IMAGE_CONTENT_TYPES.include?(content_type)
        [ { type: "image", data: Base64.strict_encode64(material.file.download), mimeType: content_type } ]
      else
        [ {
          type: "resource",
          resource: {
            uri: "file:///#{document.name}/#{blob.filename}",
            mimeType: content_type,
            blob: Base64.strict_encode64(material.file.download)
          }
        } ]
      end

      MCP::Tool::Response.new(content)
    end

    private

    def error_response(message)
      MCP::Tool::Response.new(
        [ { type: "text", text: message } ],
        error: true
      )
    end
  end
end
