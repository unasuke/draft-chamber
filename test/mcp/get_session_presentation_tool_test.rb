# frozen_string_literal: true

require "test_helper"

class GetSessionPresentationToolTest < ActiveSupport::TestCase
  test "returns presentation with document details and material URL" do
    response = GetSessionPresentationTool.call(
      server_context: {}, document_name: "slides-124-tls-chairs"
    )
    result = JSON.parse(response.content.first[:text])
    presentation = result.first

    assert_equal 1, presentation["order"]
    assert_equal "01", presentation["rev"]
    assert_equal "slides-124-tls-chairs", presentation["document"]["name"]
    assert_equal "TLS Chairs Slides", presentation["document"]["title"]
    assert_equal "slides", presentation["document"]["type"]
    assert_includes presentation["material_url"], "datatracker.ietf.org"
    assert_includes presentation["material_url"], "124"
    assert_includes presentation["material_url"], "slides-124-tls-chairs"
    assert_equal false, presentation["document"]["file_available"]
    assert_nil presentation["document"]["file_download_status"]
  end

  test "includes session and meeting information" do
    response = GetSessionPresentationTool.call(
      server_context: {}, document_name: "slides-124-tls-chairs"
    )
    result = JSON.parse(response.content.first[:text])
    session = result.first["session"]

    assert_equal 34365, session["id"]
    assert_equal "tls", session["group"]
    assert_equal "124", session["meeting_number"]
  end

  test "returns error for non-existent document" do
    response = GetSessionPresentationTool.call(
      server_context: {}, document_name: "nonexistent-doc"
    )

    assert response.error?
    assert_includes response.content.first[:text], "Document"
  end

  test "returns error when document has no presentations" do
    response = GetSessionPresentationTool.call(
      server_context: {}, document_name: "slides-124-plenary"
    )

    assert response.error?
    assert_includes response.content.first[:text], "No presentation found"
  end

  test "returns text file content when material is attached with text content type" do
    document = documents(:tls_chairs_slides)
    material = document.create_document_material!(download_status: :pending)
    material.file.attach(
      io: StringIO.new("Hello, IETF!"),
      filename: "slides.txt",
      content_type: "text/plain"
    )
    material.update!(download_status: :completed)

    response = GetSessionPresentationTool.call(
      server_context: {}, document_name: "slides-124-tls-chairs"
    )

    assert_equal 2, response.content.size
    assert_equal "text", response.content.second[:type]
    assert_equal "Hello, IETF!", response.content.second[:text]
  end

  test "returns text content when material is attached with JSON content type" do
    document = documents(:tls_chairs_slides)
    material = document.create_document_material!(download_status: :pending)
    material.file.attach(
      io: StringIO.new('{"key": "value"}'),
      filename: "data.json",
      content_type: "application/json"
    )
    material.update!(download_status: :completed)

    response = GetSessionPresentationTool.call(
      server_context: {}, document_name: "slides-124-tls-chairs"
    )

    assert_equal 2, response.content.size
    assert_equal "text", response.content.second[:type]
    assert_equal '{"key": "value"}', response.content.second[:text]
  end

  test "returns image content when material is attached with image content type" do
    document = documents(:tls_chairs_slides)
    material = document.create_document_material!(download_status: :pending)
    image_data = "\x89PNG\r\n\x1a\n" + ("x" * 100)
    material.file.attach(
      io: StringIO.new(image_data),
      filename: "slides.png",
      content_type: "image/png"
    )
    material.update!(download_status: :completed)

    response = GetSessionPresentationTool.call(
      server_context: {}, document_name: "slides-124-tls-chairs"
    )

    assert_equal 2, response.content.size
    assert_equal "image", response.content.second[:type]
    assert_equal Base64.strict_encode64(image_data), response.content.second[:data]
    assert_equal "image/png", response.content.second[:mimeType]
  end

  test "returns resource URI text when material is attached with binary content type" do
    document = documents(:tls_chairs_slides)
    material = document.create_document_material!(download_status: :pending)
    pdf_data = "%PDF-1.4 sample content"
    material.file.attach(
      io: StringIO.new(pdf_data),
      filename: "slides.pdf",
      content_type: "application/pdf"
    )
    material.update!(download_status: :completed)

    response = GetSessionPresentationTool.call(
      server_context: {}, document_name: "slides-124-tls-chairs"
    )

    assert_equal 2, response.content.size
    text_content = response.content.second
    assert_equal "text", text_content[:type]
    assert_includes text_content[:text], "file:///slides-124-tls-chairs/slides.pdf"
    assert_includes text_content[:text], "application/pdf"
  end

  test "does not return file content when material is not attached" do
    response = GetSessionPresentationTool.call(
      server_context: {}, document_name: "slides-124-tls-chairs"
    )

    assert_equal 1, response.content.size
    assert_equal "text", response.content.first[:type]
  end
end
