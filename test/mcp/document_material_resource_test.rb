# frozen_string_literal: true

require "test_helper"

class DocumentMaterialResourceTest < ActiveSupport::TestCase
  test "list_resources returns only completed materials" do
    create_material(documents(:tls_chairs_slides),
      content: "content", filename: "slides.txt", content_type: "text/plain")

    # Create a pending material that should not appear
    pending_doc = documents(:tls_agenda)
    pending_material = pending_doc.create_document_material!(download_status: :pending)
    pending_material.file.attach(
      io: StringIO.new("pending content"),
      filename: "agenda.txt",
      content_type: "text/plain"
    )

    resources = DocumentMaterialResource.list_resources({})

    assert_equal 1, resources.size
    resource = resources.first
    assert_equal "file:///slides-124-tls-chairs/slides.txt", resource[:uri]
    assert_equal "slides-124-tls-chairs", resource[:name]
    assert_equal "TLS Chairs Slides", resource[:title]
    assert_equal "text/plain", resource[:mimeType]
  end

  test "list_resources returns empty array when no completed materials exist" do
    resources = DocumentMaterialResource.list_resources({})

    assert_equal [], resources
  end

  test "list_resources includes size and description" do
    create_material(documents(:tls_chairs_slides),
      content: "Hello, IETF!", filename: "slides.txt", content_type: "text/plain")

    resource = DocumentMaterialResource.list_resources({}).first

    assert_equal "Slides - TLS Chairs Slides", resource[:description]
    assert resource[:size].positive?
  end

  test "read_resource returns text content for text files" do
    create_material(documents(:tls_chairs_slides),
      content: "Hello, IETF!", filename: "slides.txt", content_type: "text/plain")

    uri = "file:///slides-124-tls-chairs/slides.txt"
    contents = DocumentMaterialResource.read_resource(uri: uri)

    assert_equal 1, contents.size
    assert_equal uri, contents.first[:uri]
    assert_equal "text/plain", contents.first[:mimeType]
    assert_equal "Hello, IETF!", contents.first[:text]
    assert_nil contents.first[:blob]
  end

  test "read_resource returns text content for JSON files" do
    create_material(documents(:tls_chairs_slides),
      content: '{"key": "value"}', filename: "data.json", content_type: "application/json")

    uri = "file:///slides-124-tls-chairs/data.json"
    contents = DocumentMaterialResource.read_resource(uri: uri)

    assert_equal 1, contents.size
    assert_equal uri, contents.first[:uri]
    assert_equal "application/json", contents.first[:mimeType]
    assert_equal '{"key": "value"}', contents.first[:text]
    assert_nil contents.first[:blob]
  end

  test "read_resource returns converted text for processed PDF" do
    material = create_material(documents(:tls_agenda),
      content: "%PDF", filename: "agenda.pdf", content_type: "application/pdf",
      processing_status: :processing_completed)
    material.converted_document_materials.create!(
      page_number: 1, content_type: "text/plain",
      byte_size: 18, extracted_text: "Extracted PDF text"
    )

    uri = "file:///agenda-124-tls/agenda.pdf"
    contents = DocumentMaterialResource.read_resource(uri: uri)

    assert_equal 1, contents.size
    assert_equal uri, contents.first[:uri]
    assert_equal "text/plain", contents.first[:mimeType]
    assert_equal "Extracted PDF text", contents.first[:text]
  end

  test "read_resource returns converted images for processed slide PDF" do
    material = create_material(documents(:tls_chairs_slides),
      content: "%PDF", filename: "slides.pdf", content_type: "application/pdf",
      processing_status: :processing_completed)

    converted = material.converted_document_materials.create!(
      page_number: 1, content_type: "image/png", byte_size: 4
    )
    converted.file.attach(
      io: StringIO.new("IMG1"), filename: "page-1.png", content_type: "image/png"
    )

    uri = "file:///slides-124-tls-chairs/slides.pdf"
    contents = DocumentMaterialResource.read_resource(uri: uri)

    assert_equal 1, contents.size
    assert_equal uri, contents.first[:uri]
    assert_equal "image/png", contents.first[:mimeType]
    assert_equal Base64.strict_encode64("IMG1"), contents.first[:blob]
  end

  test "read_resource returns processing message for unfinished PDF" do
    create_material(documents(:tls_chairs_slides),
      content: "%PDF", filename: "slides.pdf", content_type: "application/pdf",
      processing_status: :processing)

    uri = "file:///slides-124-tls-chairs/slides.pdf"
    contents = DocumentMaterialResource.read_resource(uri: uri)

    assert_equal 1, contents.size
    assert_includes contents.first[:text], "still being processed"
  end

  test "read_resource raises error for invalid URI" do
    assert_raises(RuntimeError, "Invalid resource URI") do
      DocumentMaterialResource.read_resource(uri: "invalid://uri")
    end
  end

  test "read_resource raises error for non-existent document" do
    assert_raises(ActiveRecord::RecordNotFound) do
      DocumentMaterialResource.read_resource(uri: "file:///nonexistent-doc/file.pdf")
    end
  end

  test "read_resource raises error when material is not completed" do
    documents(:tls_chairs_slides).create_document_material!(download_status: :pending)

    assert_raises(RuntimeError, "Material not available") do
      DocumentMaterialResource.read_resource(uri: "file:///slides-124-tls-chairs/file.pdf")
    end
  end

  test "resource_templates returns document material template" do
    templates = DocumentMaterialResource.resource_templates

    assert_equal 1, templates.size
    template = templates.first
    assert_equal "file:///{document_name}/{filename}", template.uri_template
    assert_equal "document-material", template.name
  end

  private

  def create_material(document, content:, filename:, content_type:, processing_status: :not_applicable)
    material = document.create_document_material!(download_status: :pending)
    material.file.attach(io: StringIO.new(content), filename: filename, content_type: content_type)
    material.update!(download_status: :completed, content_type: content_type, processing_status: processing_status)
    material
  end
end
