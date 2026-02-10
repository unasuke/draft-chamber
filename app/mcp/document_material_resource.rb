# frozen_string_literal: true

module DocumentMaterialResource
  TEXT_CONTENT_TYPES = %w[text/plain text/html text/markdown].freeze

  module_function

  def resource_templates
    [
      MCP::ResourceTemplate.new(
        uri_template: "file:///{document_name}/{filename}",
        name: "document-material",
        title: "IETF Document Material",
        description: "File content of an IETF document material (slides, drafts, agendas, etc.)",
        mime_type: "application/octet-stream"
      )
    ]
  end

  def list_resources(_params)
    DocumentMaterial.completed.includes(:document, file_attachment: :blob).filter_map do |material|
      resource_hash(material)
    end
  end

  def read_resource(params)
    uri = params[:uri]
    match = uri.match(%r{\Afile:///([^/]+)/(.+)\z})
    raise "Invalid resource URI: #{uri}" unless match

    document_name = match[1]
    document = Document.find_by!(name: document_name)
    material = document.document_material
    raise "Material not available for document: #{document_name}" unless material&.completed? && material.file.attached?

    blob = material.file.blob
    content_type = blob.content_type

    if TEXT_CONTENT_TYPES.include?(content_type)
      [ { uri: uri, mimeType: content_type, text: material.file.download.force_encoding("UTF-8") } ]
    else
      [ { uri: uri, mimeType: content_type, blob: Base64.strict_encode64(material.file.download) } ]
    end
  end

  def resource_hash(material)
    return unless material.file.attached?

    blob = material.file.blob
    document = material.document

    {
      uri: "file:///#{document.name}/#{blob.filename}",
      name: document.name,
      title: document.title,
      description: "#{document.document_type&.capitalize} - #{document.title}",
      mimeType: blob.content_type,
      size: blob.byte_size
    }
  end
end
