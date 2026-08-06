# frozen_string_literal: true

class ProcessDocumentMaterialJob < ApplicationJob
  queue_as :default

  discard_on ActiveRecord::RecordNotFound

  def perform(material_id)
    material = DocumentMaterial.find(material_id)
    return unless material.processable?
    return if material.processing_completed?

    material.update!(processing_status: :processing)

    processor = DocumentProcessor.new

    material.file.open do |tempfile|
      if material.presentation?
        process_presentation(material, processor, tempfile)
      elsif material.pdf? && material.slide_document?
        process_slide_pdf(material, processor, tempfile)
      elsif material.pdf?
        process_text_pdf(material, processor, tempfile)
      end
    end

    material.update!(processing_status: :processing_completed)
  rescue DocumentProcessor::ProcessingError => e
    material&.update!(processing_status: :processing_failed, processing_error: e.message)
    raise
  end

  private

  def process_presentation(material, processor, tempfile)
    pdf_path = processor.convert_presentation_to_pdf(tempfile.path)
    create_page_images(material, processor, pdf_path)
  ensure
    File.delete(pdf_path) if pdf_path && File.exist?(pdf_path)
  end

  def process_slide_pdf(material, processor, tempfile)
    create_page_images(material, processor, tempfile.path)
  end

  def process_text_pdf(material, processor, tempfile)
    text = processor.extract_text(tempfile.path)
    material.converted_document_materials.create!(
      page_number: 1,
      content_type: "text/plain",
      byte_size: text.bytesize,
      extracted_text: text
    )
    material.update!(text_extracted_at: Time.current)
  end

  def create_page_images(material, processor, pdf_path)
    images = processor.convert_to_images(pdf_path)
    page_texts = extract_page_texts(processor, pdf_path)

    images.each do |image|
      converted = material.converted_document_materials.create!(
        page_number: image[:page_number],
        content_type: image[:content_type],
        byte_size: image[:byte_size],
        extracted_text: page_texts.fetch(image[:page_number], "")
      )
      converted.file.attach(
        io: image[:io],
        filename: image[:filename],
        content_type: image[:content_type]
      )
    end

    material.update!(text_extracted_at: Time.current)
  end

  # Returns an empty hash when the file cannot be processed at all
  def extract_page_texts(processor, pdf_path)
    processor.extract_page_texts(pdf_path)
  rescue DocumentProcessor::ProcessingError => e
    Rails.logger.warn("[ProcessDocumentMaterialJob] Text extraction failed for #{pdf_path}: #{e.message}")
    {}
  end
end
