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

  test "belongs to document" do
    material = DocumentMaterial.create!(
      document: documents(:tls_agenda),
      download_status: :pending
    )
    assert_equal documents(:tls_agenda), material.document
  end
end
