# frozen_string_literal: true

class BackfillSlideTextJob < ApplicationJob
  queue_as :default
  queue_with_priority 100

  BATCH_SIZE = 10
  THROTTLE_DURATION = 3.0

  limits_concurrency to: 1, key: "backfill_slide_text", duration: 10.minutes, on_conflict: :discard

  def perform
    materials = DocumentMaterial.slide_text_pending.limit(BATCH_SIZE).to_a
    return if materials.empty?

    Rails.logger.info("[BackfillSlideTextJob] Extracting text for #{materials.size} slide materials")

    materials.each_with_index do |material, index|
      sleep THROTTLE_DURATION unless index.zero?
      ExtractSlideTextJob.perform_now(material.id)
    rescue StandardError => e
      Rails.logger.warn("[BackfillSlideTextJob] Failed for #{material.document.name}: #{e.class}: #{e.message}")
    end
  end
end
