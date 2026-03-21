# frozen_string_literal: true

require "test_helper"

class ReadDocumentMaterialToolTest < ActiveSupport::TestCase
  test "returns text content for text file" do
    material = create_material(documents(:tls_chairs_slides),
      content: "Hello, IETF!", filename: "slides.txt", content_type: "text/plain")

    response = ReadDocumentMaterialTool.call(
      server_context: {}, document_name: "slides-124-tls-chairs"
    )

    assert_equal 1, response.content.size
    assert_equal "text", response.content.first[:type]
    assert_equal "Hello, IETF!", response.content.first[:text]
  end

  test "returns text content for JSON file" do
    create_material(documents(:tls_chairs_slides),
      content: '{"key": "value"}', filename: "data.json", content_type: "application/json")

    response = ReadDocumentMaterialTool.call(
      server_context: {}, document_name: "slides-124-tls-chairs"
    )

    assert_equal 1, response.content.size
    assert_equal "text", response.content.first[:type]
    assert_equal '{"key": "value"}', response.content.first[:text]
  end

  test "returns image content for image file" do
    image_data = "\x89PNG\r\n\x1a\n" + ("x" * 100)
    material = create_material(documents(:tls_chairs_slides),
      content: image_data, filename: "slides.png", content_type: "image/png")

    response = ReadDocumentMaterialTool.call(
      server_context: {}, document_name: "slides-124-tls-chairs"
    )

    assert_equal 1, response.content.size
    assert_equal "image", response.content.first[:type]
    assert_equal Base64.strict_encode64(image_data), response.content.first[:data]
    assert_equal "image/png", response.content.first[:mimeType]
  end

  test "returns converted text for processed text PDF" do
    material = create_material(documents(:tls_agenda),
      content: "%PDF", filename: "agenda.pdf", content_type: "application/pdf",
      processing_status: :processing_completed)
    material.converted_document_materials.create!(
      page_number: 1, content_type: "text/plain",
      byte_size: 18, extracted_text: "Extracted PDF text"
    )

    response = ReadDocumentMaterialTool.call(
      server_context: {}, document_name: "agenda-124-tls"
    )

    assert_equal 1, response.content.size
    assert_equal "text", response.content.first[:type]
    assert_equal "Extracted PDF text", response.content.first[:text]
  end

  test "returns converted images for processed slide PDF" do
    material = create_material(documents(:tls_chairs_slides),
      content: "%PDF", filename: "slides.pdf", content_type: "application/pdf",
      processing_status: :processing_completed)

    2.times do |i|
      converted = material.converted_document_materials.create!(
        page_number: i + 1, content_type: "image/png", byte_size: 5
      )
      converted.file.attach(
        io: StringIO.new("IMG#{i + 1}"),
        filename: "page-#{i + 1}.png",
        content_type: "image/png"
      )
    end

    response = ReadDocumentMaterialTool.call(
      server_context: {}, document_name: "slides-124-tls-chairs"
    )

    assert_equal 2, response.content.size
    assert_equal "image", response.content[0][:type]
    assert_equal "image/png", response.content[0][:mimeType]
    assert_equal Base64.strict_encode64("IMG1"), response.content[0][:data]
    assert_equal "image", response.content[1][:type]
    assert_equal Base64.strict_encode64("IMG2"), response.content[1][:data]
  end

  test "returns processing message for PDF still being processed" do
    create_material(documents(:tls_chairs_slides),
      content: "%PDF", filename: "slides.pdf", content_type: "application/pdf",
      processing_status: :processing)

    response = ReadDocumentMaterialTool.call(
      server_context: {}, document_name: "slides-124-tls-chairs"
    )

    assert_equal 1, response.content.size
    assert_includes response.content.first[:text], "still being processed"
  end

  test "returns error for non-existent document" do
    response = ReadDocumentMaterialTool.call(
      server_context: {}, document_name: "nonexistent-doc"
    )

    assert response.error?
    assert_includes response.content.first[:text], "not found"
  end

  test "returns error when material is not available" do
    documents(:tls_chairs_slides).create_document_material!(download_status: :pending)

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

  private

  def create_material(document, content:, filename:, content_type:, processing_status: :not_applicable)
    material = document.create_document_material!(download_status: :pending)
    material.file.attach(io: StringIO.new(content), filename: filename, content_type: content_type)
    material.update!(download_status: :completed, content_type: content_type, processing_status: processing_status)
    material
  end
end
