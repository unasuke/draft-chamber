# frozen_string_literal: true

class ExtractSlideTextJob < ApplicationJob
  queue_as :default

  discard_on ActiveRecord::RecordNotFound

  def perform(material_id)
    material = DocumentMaterial.find(material_id)
    return unless material.slide_document? && material.processable? && material.processing_completed?
    return unless material.file.attached?
    return if material.text_extracted_at?

    processor = DocumentProcessor.new
    material.file.open do |tempfile|
      pdf_path = material.presentation? ? processor.convert_presentation_to_pdf(tempfile.path) : tempfile.path
      begin
        apply_page_texts(material, processor.extract_page_texts(pdf_path))
      ensure
        File.delete(pdf_path) if material.presentation? && pdf_path && File.exist?(pdf_path)
      end
    end

    material.update!(text_extracted_at: Time.current)
    Rails.logger.info("[ExtractSlideTextJob] Extracted text for #{material.document.name}")
  rescue DocumentProcessor::ProcessingError => e
    Rails.logger.warn("[ExtractSlideTextJob] Extraction failed for #{material.document.name}: #{e.message}")
    material.update!(text_extracted_at: Time.current)
  end

  private

  def apply_page_texts(material, page_texts)
    page_texts.each do |page_number, text|
      converted = material.converted_document_materials.find_by(page_number: page_number)
      if converted
        converted.update!(extracted_text: text)
      else
        Rails.logger.warn("[ExtractSlideTextJob] No converted page #{page_number} for #{material.document.name}, skipping")
      end
    end
  end
end
