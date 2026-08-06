# frozen_string_literal: true

namespace :document_processing do
  desc "Enqueue processing jobs for downloaded but unprocessed PDF/PPTX/PPT materials"
  task backfill: :environment do
    materials = DocumentMaterial
      .where(download_status: :completed, processing_status: :not_applicable)
      .where(content_type: DocumentMaterial::PROCESSABLE_CONTENT_TYPES)

    count = 0
    materials.find_each do |material|
      material.update!(processing_status: :processing_pending)
      ProcessDocumentMaterialJob.perform_later(material.id)
      count += 1
    end

    puts "Enqueued #{count} document materials for processing"
  end

  desc "Backfill extracted text into already-processed slide pages"
  task backfill_slide_text: :environment do
    count = 0
    DocumentMaterial.slide_text_pending.reorder(:id).find_each do |material|
      ExtractSlideTextJob.set(priority: 100).perform_later(material.id)
      count += 1
    end

    puts "Enqueued #{count} slide materials for text extraction"
  end
end
