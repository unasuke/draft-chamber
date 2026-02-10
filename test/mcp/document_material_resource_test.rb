# frozen_string_literal: true

require "test_helper"

class DocumentMaterialResourceTest < ActiveSupport::TestCase
  test "list_resources returns only completed materials" do
    document = documents(:tls_chairs_slides)
    material = document.create_document_material!(download_status: :pending)
    material.file.attach(
      io: StringIO.new("content"),
      filename: "slides.txt",
      content_type: "text/plain"
    )
    material.update!(download_status: :completed)

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
    document = documents(:tls_chairs_slides)
    material = document.create_document_material!(download_status: :pending)
    material.file.attach(
      io: StringIO.new("Hello, IETF!"),
      filename: "slides.txt",
      content_type: "text/plain"
    )
    material.update!(download_status: :completed)

    resource = DocumentMaterialResource.list_resources({}).first

    assert_equal "Slides - TLS Chairs Slides", resource[:description]
    assert resource[:size].positive?
  end

  test "read_resource returns text content for text files" do
    document = documents(:tls_chairs_slides)
    material = document.create_document_material!(download_status: :pending)
    material.file.attach(
      io: StringIO.new("Hello, IETF!"),
      filename: "slides.txt",
      content_type: "text/plain"
    )
    material.update!(download_status: :completed)

    uri = "file:///slides-124-tls-chairs/slides.txt"
    contents = DocumentMaterialResource.read_resource(uri: uri)

    assert_equal 1, contents.size
    assert_equal uri, contents.first[:uri]
    assert_equal "text/plain", contents.first[:mimeType]
    assert_equal "Hello, IETF!", contents.first[:text]
    assert_nil contents.first[:blob]
  end

  test "read_resource returns blob content for binary files" do
    document = documents(:tls_chairs_slides)
    material = document.create_document_material!(download_status: :pending)
    pdf_data = "%PDF-1.4 sample content"
    material.file.attach(
      io: StringIO.new(pdf_data),
      filename: "slides.pdf",
      content_type: "application/pdf"
    )
    material.update!(download_status: :completed)

    uri = "file:///slides-124-tls-chairs/slides.pdf"
    contents = DocumentMaterialResource.read_resource(uri: uri)

    assert_equal 1, contents.size
    assert_equal uri, contents.first[:uri]
    assert_equal "application/pdf", contents.first[:mimeType]
    assert_equal Base64.strict_encode64(pdf_data), contents.first[:blob]
    assert_nil contents.first[:text]
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
    document = documents(:tls_chairs_slides)
    document.create_document_material!(download_status: :pending)

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
end
