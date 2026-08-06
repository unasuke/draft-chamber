# frozen_string_literal: true

require "test_helper"

class ReadSlideTextToolTest < ActiveSupport::TestCase
  test "returns one entry per page and repeats the payload as JSON text" do
    material = create_slide_material
    create_page(material, 1, "qlog: Structured Logging for QUIC")
    create_page(material, 2, "Motivation")

    response = call_tool("slides-124-tls-chairs")

    data = response.structured_content
    assert_equal "slides-124-tls-chairs", data[:document_name]
    assert_equal 2, data[:total_pages]
    assert_equal false, data[:truncated]
    assert_nil data[:notice]
    assert_equal [
      { page_number: 1, text: "qlog: Structured Logging for QUIC" },
      { page_number: 2, text: "Motivation" }
    ], data[:pages]

    assert_equal 1, response.content.size
    assert_equal "text", response.content.first[:type]
    assert_equal data.deep_stringify_keys, JSON.parse(response.content.first[:text])
  end

  test "structured content satisfies the declared output schema" do
    material = create_slide_material
    create_page(material, 1, "Motivation")

    response = call_tool("slides-124-tls-chairs")

    assert_nothing_raised do
      ReadSlideTextTool.output_schema.validate_result(response.structured_content)
    end
  end

  test "substitutes a placeholder for pages without text" do
    material = create_slide_material
    create_page(material, 1, "Motivation")
    create_page(material, 2, "")

    data = call_tool("slides-124-tls-chairs").structured_content

    assert_equal "(no extractable text on this page)", data[:pages].last[:text]
    assert_nil data[:notice]
  end

  test "notices an image-based deck when no page has text" do
    material = create_slide_material
    create_page(material, 1, "")
    create_page(material, 2, "")

    data = call_tool("slides-124-tls-chairs").structured_content

    assert_equal 2, data[:total_pages]
    assert_includes data[:notice], "image-based"
    assert_nothing_raised do
      ReadSlideTextTool.output_schema.validate_result(data)
    end
  end

  test "flags a deck that reached the page limit as truncated" do
    material = create_slide_material
    DocumentProcessor::MAX_PAGES.times { |i| create_page(material, i + 1, "Page #{i + 1}") }

    data = call_tool("slides-124-tls-chairs").structured_content

    assert_equal DocumentProcessor::MAX_PAGES, data[:total_pages]
    assert_equal true, data[:truncated]
  end

  test "returns no pages for a document that is not a slide document" do
    create_slide_material(document: documents(:tls_agenda), processing_status: :processing_completed)

    data = call_tool("agenda-124-tls").structured_content

    assert_equal [], data[:pages]
    assert_equal 0, data[:total_pages]
    assert_includes data[:notice], "is not a slide document"
  end

  test "distinguishes a document still being processed from one that failed" do
    create_slide_material(processing_status: :processing)
    processing = call_tool("slides-124-tls-chairs").structured_content

    DocumentMaterial.find_by(document: documents(:tls_chairs_slides)).update!(processing_status: :processing_failed)
    failed = call_tool("slides-124-tls-chairs").structured_content

    assert_includes processing[:notice], "still being processed"
    assert_includes failed[:notice], "Processing this document failed"
    assert_equal [], processing[:pages]
    assert_equal [], failed[:pages]
  end

  test "returns an error for a non-existent document" do
    response = call_tool("nonexistent-doc")

    assert response.error?
    assert_includes response.content.first[:text], "not found"
  end

  test "returns an error when the material is not available" do
    documents(:tls_chairs_slides).create_document_material!(download_status: :pending)

    response = call_tool("slides-124-tls-chairs")

    assert response.error?
    assert_includes response.content.first[:text], "not available"
  end

  private

  def call_tool(document_name)
    ReadSlideTextTool.call(server_context: {}, document_name: document_name)
  end

  def create_slide_material(document: documents(:tls_chairs_slides), processing_status: :processing_completed)
    material = document.create_document_material!(download_status: :pending)
    material.file.attach(io: StringIO.new("%PDF"), filename: "slides.pdf", content_type: "application/pdf")
    material.update!(
      download_status: :completed,
      content_type: "application/pdf",
      processing_status: processing_status
    )
    material
  end

  def create_page(material, page_number, text)
    material.converted_document_materials.create!(
      page_number: page_number,
      content_type: "image/png",
      byte_size: 4,
      extracted_text: text
    )
  end
end
