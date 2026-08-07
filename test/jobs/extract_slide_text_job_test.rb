# frozen_string_literal: true

require "test_helper"

class ExtractSlideTextJobTest < ActiveSupport::TestCase
  test "fills the extracted text of the existing page records" do
    material = create_material
    create_page(material, 1)
    create_page(material, 2)

    perform_with_page_texts(material, { 1 => "Motivation", 2 => "Conclusion" })

    assert_equal "Motivation", material.converted_document_materials.find_by(page_number: 1).extracted_text
    assert_equal "Conclusion", material.converted_document_materials.find_by(page_number: 2).extracted_text
    assert_not_nil material.reload.text_extracted_at
  end

  test "skips pages that have no image record instead of creating one" do
    material = create_material
    create_page(material, 1)

    perform_with_page_texts(material, { 1 => "Motivation", 2 => "Orphaned page" })

    assert_equal 1, material.converted_document_materials.count
    assert_equal "Motivation", material.converted_document_materials.first.extracted_text
  end

  test "skips a material whose text has already been extracted" do
    material = create_material(text_extracted_at: 1.day.ago)
    create_page(material, 1)

    DocumentProcessor.stub(:new, ->(*) { flunk("processor must not be built") }) do
      ExtractSlideTextJob.perform_now(material.id)
    end

    assert_equal "", material.converted_document_materials.first.extracted_text
  end

  test "skips a material that is not a slide document" do
    material = create_material(document: documents(:tls_agenda))
    create_page(material, 1)

    DocumentProcessor.stub(:new, ->(*) { flunk("processor must not be built") }) do
      ExtractSlideTextJob.perform_now(material.id)
    end

    assert_nil material.reload.text_extracted_at
  end

  test "skips a material that is not processed yet" do
    material = create_material(processing_status: :processing_pending)

    DocumentProcessor.stub(:new, ->(*) { flunk("processor must not be built") }) do
      ExtractSlideTextJob.perform_now(material.id)
    end

    assert_nil material.reload.text_extracted_at
  end

  test "records the extraction as settled when pdftotext rejects the file" do
    material = create_material
    create_page(material, 1)

    processor = Object.new
    def processor.extract_page_texts(_path)
      raise DocumentProcessor::ProcessingError, "pdftotext failed: broken file"
    end

    assert_nothing_raised do
      DocumentProcessor.stub(:new, processor) do
        ExtractSlideTextJob.perform_now(material.id)
      end
    end

    assert_not_nil material.reload.text_extracted_at
    assert_equal "processing_completed", material.processing_status
  end

  test "leaves the material for a later retry when the failure is not about the file" do
    material = create_material
    create_page(material, 1)

    processor = Object.new
    def processor.extract_page_texts(_path)
      raise Errno::ECONNRESET, "connection reset"
    end

    assert_raises(Errno::ECONNRESET) do
      DocumentProcessor.stub(:new, processor) do
        ExtractSlideTextJob.perform_now(material.id)
      end
    end

    assert_nil material.reload.text_extracted_at
  end

  test "discards the job when the material is gone" do
    assert_nothing_raised do
      ExtractSlideTextJob.perform_now(-1)
    end
  end

  private

  def perform_with_page_texts(material, page_texts)
    mock_processor = Minitest::Mock.new
    mock_processor.expect(:extract_page_texts, page_texts, [ String ])

    DocumentProcessor.stub(:new, mock_processor) do
      ExtractSlideTextJob.perform_now(material.id)
    end

    mock_processor.verify
  end

  def create_material(document: documents(:tls_chairs_slides), processing_status: :processing_completed, **attributes)
    material = document.create_document_material!(download_status: :pending)
    material.file.attach(io: StringIO.new("%PDF"), filename: "slides.pdf", content_type: "application/pdf")
    material.update!(
      download_status: :completed,
      content_type: "application/pdf",
      processing_status: processing_status,
      **attributes
    )
    material
  end

  def create_page(material, page_number)
    converted = material.converted_document_materials.create!(
      page_number: page_number,
      content_type: "image/png",
      byte_size: 4
    )
    converted.file.attach(
      io: StringIO.new("IMG#{page_number}"),
      filename: "page-#{page_number}.png",
      content_type: "image/png"
    )
    converted
  end
end
