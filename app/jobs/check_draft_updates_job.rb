# frozen_string_literal: true

class CheckDraftUpdatesJob < ApplicationJob
  include DatatrackerImportJob

  def perform(draft_name)
    tracked_draft = TrackedDraft.find_by!(draft_name: draft_name)
    client = Datatracker::Client.new

    response = client.new_revision_doc_events.for_document(draft_name, limit: 1, order_by: "-id")
    latest_event = response.objects.first

    unless latest_event
      tracked_draft.update!(last_checked_at: Time.current)
      return
    end

    latest_rev = latest_event["rev"]

    if tracked_draft.last_known_rev != latest_rev
      ensure_document_exists(client, draft_name, tracked_draft)
      tracked_draft.update!(last_known_rev: latest_rev, last_checked_at: Time.current)
    else
      tracked_draft.update!(last_checked_at: Time.current)
    end
  rescue Datatracker::NotFoundError
    Rails.logger.warn("[CheckDraftUpdatesJob] Draft not found: #{draft_name}")
    tracked_draft&.update!(last_checked_at: Time.current)
  end

  private

  def ensure_document_exists(client, draft_name, tracked_draft)
    return if tracked_draft.document.present?

    importer = DatatrackerImport::DocumentImporter.new(client: client)
    importer.import(document_uris: [ "/api/v1/doc/document/#{draft_name}/" ])

    document = Document.find_by(name: draft_name)
    tracked_draft.update!(document: document) if document
  end
end
