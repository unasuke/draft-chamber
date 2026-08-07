# frozen_string_literal: true

require "test_helper"

class DocumentMaterialTest < ActiveSupport::TestCase
  test "valid document material with file attached" do
    material = DocumentMaterial.new(
      document: documents(:tls_chairs_slides),
      download_status: :completed
    )
    material.file.attach(
      io: File.open(Rails.root.join("test/fixtures/files/sample_document.txt")),
      filename: "slides-124-tls-chairs.pdf",
      content_type: "application/pdf"
    )
    assert material.valid?
  end

  test "requires document" do
    material = DocumentMaterial.new(download_status: :pending)
    assert_not material.valid?
    assert_includes material.errors[:document], "must exist"
  end

  test "pending material does not require file" do
    material = DocumentMaterial.new(
      document: documents(:tls_chairs_slides),
      download_status: :pending
    )
    assert material.valid?
  end

  test "downloading material does not require file" do
    material = DocumentMaterial.new(
      document: documents(:tls_chairs_slides),
      download_status: :downloading
    )
    assert material.valid?
  end

  test "failed material does not require file" do
    material = DocumentMaterial.new(
      document: documents(:tls_chairs_slides),
      download_status: :failed
    )
    assert material.valid?
  end

  test "completed material requires file" do
    material = DocumentMaterial.new(
      document: documents(:tls_chairs_slides),
      download_status: :completed
    )
    assert_not material.valid?
    assert_includes material.errors[:file], "must be attached"
  end

  test "document must be unique" do
    DocumentMaterial.create!(
      document: documents(:tls_chairs_slides),
      download_status: :pending
    )
    duplicate = DocumentMaterial.new(
      document: documents(:tls_chairs_slides),
      download_status: :pending
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:document_id], "has already been taken"
  end

  test "validates content type when file attached" do
    material = DocumentMaterial.new(
      document: documents(:tls_chairs_slides),
      download_status: :completed
    )
    material.file.attach(
      io: StringIO.new("content"),
      filename: "test.bin",
      content_type: "application/x-unknown"
    )
    assert_not material.valid?
    assert material.errors[:file].any? { |e| e.include?("unsupported content type") }
  end

  test "text? returns true for text content types" do
    material = DocumentMaterial.new(document: documents(:tls_chairs_slides), download_status: :pending)

    material.content_type = "text/plain"
    assert material.text?

    material.content_type = "text/html"
    assert material.text?

    material.content_type = "text/markdown"
    assert material.text?

    material.content_type = "application/json"
    assert material.text?
  end

  test "text? returns false for non-text content types" do
    material = DocumentMaterial.new(document: documents(:tls_chairs_slides), download_status: :pending)

    material.content_type = "application/pdf"
    assert_not material.text?

    material.content_type = "image/png"
    assert_not material.text?
  end

  test "slide_text_pending returns processed slide materials without extracted text, newest first" do
    older = create_pending_material(documents(:tls_chairs_slides), downloaded_at: 2.days.ago)
    newer = create_pending_material(documents(:ungrouped_doc), downloaded_at: 1.hour.ago)

    assert_equal [ newer, older ], DocumentMaterial.slide_text_pending.to_a
  end

  test "slide_text_pending excludes materials whose text has been extracted" do
    create_pending_material(documents(:tls_chairs_slides), text_extracted_at: Time.current)

    assert_empty DocumentMaterial.slide_text_pending
  end

  test "slide_text_pending excludes documents that are not slides" do
    create_pending_material(documents(:tls_agenda))

    assert_empty DocumentMaterial.slide_text_pending
  end

  test "slide_text_pending excludes materials that are not processed yet" do
    create_pending_material(documents(:tls_chairs_slides), processing_status: :processing_pending)

    assert_empty DocumentMaterial.slide_text_pending
  end

  test "belongs to document" do
    material = DocumentMaterial.create!(
      document: documents(:tls_agenda),
      download_status: :pending
    )
    assert_equal documents(:tls_agenda), material.document
  end

  private

  def create_pending_material(document, processing_status: :processing_completed, **attributes)
    DocumentMaterial.create!(
      document: document,
      download_status: :pending,
      content_type: DocumentMaterial::PDF_CONTENT_TYPE,
      processing_status: processing_status,
      **attributes
    )
  end
end
