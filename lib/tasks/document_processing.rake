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
end
