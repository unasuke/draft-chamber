# frozen_string_literal: true

class ReadSlideTextTool < MCP::Tool
  EMPTY_PAGE_PLACEHOLDER = "(no extractable text on this page)"
  IMAGE_BASED_NOTICE = "This deck appears to be image-based. Use read_document_material_tool to see the pages."
  STILL_PROCESSING_NOTICE = "Document is still being processed. Please try again later."
  PROCESSING_FAILED_NOTICE = "Processing this document failed. Use read_document_material_tool to fetch the original file."

  description <<~TEXT
    Read the text extracted from each page of a slide document, without page images.
    Much cheaper than read_document_material_tool for understanding what a deck says.
    Only works for slide documents; use read_document_material_tool for anything else.
  TEXT

  annotations(
    read_only_hint: true,
    destructive_hint: false,
    idempotent_hint: true,
    open_world_hint: false
  )

  input_schema(
    properties: {
      document_name: {
        type: "string",
        description: "Document name (e.g. 'slides-124-quic-qlog')"
      }
    },
    required: %w[document_name]
  )

  output_schema(
    type: "object",
    properties: {
      document_name: { type: "string" },
      total_pages: { type: "integer" },
      truncated: { type: "boolean" },
      notice: { type: [ "string", "null" ] },
      pages: {
        type: "array",
        items: {
          type: "object",
          properties: {
            page_number: { type: "integer" },
            text: { type: "string" }
          },
          required: [ "page_number", "text" ]
        }
      }
    },
    required: [ "document_name", "total_pages", "truncated", "notice", "pages" ]
  )

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

      unless material.slide_document?
        return response(no_pages(document.name,
          "Document '#{document.name}' is not a slide document. Use read_document_material_tool instead."))
      end

      # These states change on their own, so they are answered without touching the cache.
      if material.processing_failed?
        return response(no_pages(document.name, PROCESSING_FAILED_NOTICE))
      end
      unless material.processing_completed?
        return response(no_pages(document.name, STILL_PROCESSING_NOTICE))
      end

      data = Rails.cache.fetch([ "mcp/tool/slide_text", material.cache_key_with_version ]) do
        build_data(material)
      end

      response(data)
    end

    private

    def build_data(material)
      converted = material.converted_document_materials.ordered.to_a

      {
        document_name: material.document.name,
        total_pages: converted.size,
        truncated: converted.size >= DocumentProcessor::MAX_PAGES,
        notice: converted.any? { |page| page.extracted_text.present? } ? nil : IMAGE_BASED_NOTICE,
        pages: converted.map do |page|
          { page_number: page.page_number, text: page.extracted_text.presence || EMPTY_PAGE_PLACEHOLDER }
        end
      }
    end

    def no_pages(document_name, notice)
      { document_name: document_name, total_pages: 0, truncated: false, notice: notice, pages: [] }
    end

    def response(data)
      MCP::Tool::Response.new(
        [ { type: "text", text: JSON.generate(data) } ],
        structured_content: data
      )
    end

    def error_response(message)
      MCP::Tool::Response.new(
        [ { type: "text", text: message } ],
        error: true
      )
    end
  end
end
