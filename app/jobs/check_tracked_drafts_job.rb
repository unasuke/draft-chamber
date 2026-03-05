# frozen_string_literal: true

class CheckTrackedDraftsJob < ApplicationJob
  queue_as :default

  def perform
    draft_names = TrackedDraft.active.pluck(:draft_name)
    Rails.logger.info("[CheckTrackedDraftsJob] Enqueueing check for #{draft_names.size} tracked drafts")

    draft_names.each do |name|
      CheckDraftUpdatesJob.perform_later(name)
    end
  end
end
