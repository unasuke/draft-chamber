# frozen_string_literal: true

require "test_helper"

class ProcessDocumentMaterialJobTest < ActiveSupport::TestCase
  setup do
    @slides_document = documents(:tls_chairs_slides)
    @agenda_document = documents(:tls_agenda)
  end

  test "processes slide PDF into page images" do
    material = create_material(@slides_document,
      content_type: "application/pdf",
      filename: "slides.pdf",
      processing_status: :processing_pending
    )

    mock_processor = Minitest::Mock.new
    mock_processor.expect(:convert_to_images, [
      { io: StringIO.new("IMG1"), filename: "page-1.png", content_type: "image/png", page_number: 1, byte_size: 4 },
      { io: StringIO.new("IMG2"), filename: "page-2.png", content_type: "image/png", page_number: 2, byte_size: 4 }
    ], [ String ])

    DocumentProcessor.stub(:new, mock_processor) do
      ProcessDocumentMaterialJob.perform_now(material.id)
    end

    material.reload
    assert_equal "processing_completed", material.processing_status
    assert_equal 2, material.converted_document_materials.count

    page1 = material.converted_document_materials.ordered.first
    assert_equal 1, page1.page_number
    assert_equal "image/png", page1.content_type
    assert page1.file.attached?

    mock_processor.verify
  end

  test "processes text PDF by extracting text" do
    material = create_material(@agenda_document,
      content_type: "application/pdf",
      filename: "agenda.pdf",
      processing_status: :processing_pending
    )

    mock_processor = Minitest::Mock.new
    mock_processor.expect(:extract_text, "Extracted agenda text", [ String ])

    DocumentProcessor.stub(:new, mock_processor) do
      ProcessDocumentMaterialJob.perform_now(material.id)
    end

    material.reload
    assert_equal "processing_completed", material.processing_status
    assert_equal 1, material.converted_document_materials.count

    converted = material.converted_document_materials.first
    assert_equal 1, converted.page_number
    assert_equal "text/plain", converted.content_type
    assert_equal "Extracted agenda text", converted.extracted_text

    mock_processor.verify
  end

  test "processes PPTX presentation into page images" do
    material = create_material(@slides_document,
      content_type: "application/vnd.openxmlformats-officedocument.presentationml.presentation",
      filename: "slides.pptx",
      processing_status: :processing_pending
    )

    mock_processor = Minitest::Mock.new

    Dir.mktmpdir do |tmpdir|
      pdf_path = File.join(tmpdir, "slides.pdf")
      FileUtils.touch(pdf_path)

      mock_processor.expect(:convert_presentation_to_pdf, pdf_path, [ String ])
      mock_processor.expect(:convert_to_images, [
        { io: StringIO.new("IMG1"), filename: "page-1.png", content_type: "image/png", page_number: 1, byte_size: 4 }
      ], [ String ])

      DocumentProcessor.stub(:new, mock_processor) do
        ProcessDocumentMaterialJob.perform_now(material.id)
      end
    end

    material.reload
    assert_equal "processing_completed", material.processing_status
    assert_equal 1, material.converted_document_materials.count

    mock_processor.verify
  end

  test "marks material as failed on processing error" do
    material = create_material(@agenda_document,
      content_type: "application/pdf",
      filename: "agenda.pdf",
      processing_status: :processing_pending
    )

    failing_processor = Object.new
    def failing_processor.extract_text(_path)
      raise DocumentProcessor::ProcessingError, "pdftotext crashed"
    end

    assert_raises(DocumentProcessor::ProcessingError) do
      DocumentProcessor.stub(:new, failing_processor) do
        ProcessDocumentMaterialJob.perform_now(material.id)
      end
    end

    material.reload
    assert_equal "processing_failed", material.processing_status
    assert_equal "pdftotext crashed", material.processing_error
  end

  test "skips non-processable content types" do
    material = create_material(@slides_document,
      content_type: "text/plain",
      filename: "slides.txt",
      processing_status: :not_applicable
    )

    ProcessDocumentMaterialJob.perform_now(material.id)

    assert_equal "not_applicable", material.reload.processing_status
    assert_equal 0, material.converted_document_materials.count
  end

  test "skips already completed materials" do
    material = create_material(@slides_document,
      content_type: "application/pdf",
      filename: "slides.pdf",
      processing_status: :processing_completed
    )

    ProcessDocumentMaterialJob.perform_now(material.id)

    assert_equal "processing_completed", material.reload.processing_status
  end

  test "discards job when material not found" do
    assert_nothing_raised do
      ProcessDocumentMaterialJob.perform_now(-1)
    end
  end

  private

  def create_material(document, content_type:, filename:, processing_status:)
    material = document.create_document_material!(download_status: :pending)
    material.file.attach(
      io: StringIO.new("dummy content"),
      filename: filename,
      content_type: content_type
    )
    material.update!(
      download_status: :completed,
      processing_status: processing_status,
      content_type: content_type
    )
    material
  end
end
