# frozen_string_literal: true

require "test_helper"

class ReadDocumentMaterialToolTest < ActiveSupport::TestCase
  test "returns text content for text file" do
    document = documents(:tls_chairs_slides)
    material = document.create_document_material!(download_status: :pending)
    material.file.attach(
      io: StringIO.new("Hello, IETF!"),
      filename: "slides.txt",
      content_type: "text/plain"
    )
    material.update!(download_status: :completed)

    response = ReadDocumentMaterialTool.call(
      server_context: {}, document_name: "slides-124-tls-chairs"
    )

    assert_equal 1, response.content.size
    assert_equal "text", response.content.first[:type]
    assert_equal "Hello, IETF!", response.content.first[:text]
  end

  test "returns image content for image file" do
    document = documents(:tls_chairs_slides)
    material = document.create_document_material!(download_status: :pending)
    image_data = "\x89PNG\r\n\x1a\n" + ("x" * 100)
    material.file.attach(
      io: StringIO.new(image_data),
      filename: "slides.png",
      content_type: "image/png"
    )
    material.update!(download_status: :completed)

    response = ReadDocumentMaterialTool.call(
      server_context: {}, document_name: "slides-124-tls-chairs"
    )

    assert_equal 1, response.content.size
    assert_equal "image", response.content.first[:type]
    assert_equal Base64.strict_encode64(image_data), response.content.first[:data]
    assert_equal "image/png", response.content.first[:mimeType]
  end

  test "returns resource content for binary file" do
    document = documents(:tls_chairs_slides)
    material = document.create_document_material!(download_status: :pending)
    pdf_data = "%PDF-1.4 sample content"
    material.file.attach(
      io: StringIO.new(pdf_data),
      filename: "slides.pdf",
      content_type: "application/pdf"
    )
    material.update!(download_status: :completed)

    response = ReadDocumentMaterialTool.call(
      server_context: {}, document_name: "slides-124-tls-chairs"
    )

    assert_equal 1, response.content.size
    resource_content = response.content.first
    assert_equal "resource", resource_content[:type]
    assert_equal "application/pdf", resource_content[:resource][:mimeType]
    assert_equal Base64.strict_encode64(pdf_data), resource_content[:resource][:blob]
    assert_includes resource_content[:resource][:uri], "slides-124-tls-chairs"
  end

  test "returns error for non-existent document" do
    response = ReadDocumentMaterialTool.call(
      server_context: {}, document_name: "nonexistent-doc"
    )

    assert response.error?
    assert_includes response.content.first[:text], "not found"
  end

  test "returns error when material is not available" do
    document = documents(:tls_chairs_slides)
    document.create_document_material!(download_status: :pending)

    response = ReadDocumentMaterialTool.call(
      server_context: {}, document_name: "slides-124-tls-chairs"
    )

    assert response.error?
    assert_includes response.content.first[:text], "not available"
  end

  test "returns error when no material exists" do
    response = ReadDocumentMaterialTool.call(
      server_context: {}, document_name: "slides-124-tls-chairs"
    )

    assert response.error?
    assert_includes response.content.first[:text], "not available"
  end
end
