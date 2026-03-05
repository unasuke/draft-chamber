# frozen_string_literal: true

class SyncRecentDraftRevisionsJob < ApplicationJob
  include DatatrackerImportJob

  def perform
    client = Datatracker::Client.new
    response = client.new_revision_doc_events.list(order_by: "-id", limit: 20)

    response.objects.each do |event|
      doc_name = extract_name_from_doc_uri(event["doc"])
      next unless doc_name

      tracked_draft = TrackedDraft.find_or_initialize_by(draft_name: doc_name)
      tracked_draft.status = "active" if tracked_draft.new_record?
      tracked_draft.last_known_rev = event["rev"] if event["rev"]
      tracked_draft.last_checked_at = Time.current
      tracked_draft.save!

      ensure_document_exists(client, doc_name, tracked_draft) unless tracked_draft.document
    end
  end

  private

  def extract_name_from_doc_uri(uri)
    return nil unless uri.is_a?(String)

    uri.split("/").compact_blank.last
  end

  def ensure_document_exists(client, doc_name, tracked_draft)
    importer = DatatrackerImport::DocumentImporter.new(client: client)
    importer.import(document_uris: [ "/api/v1/doc/document/#{doc_name}/" ])

    document = Document.find_by(name: doc_name)
    tracked_draft.update!(document: document) if document
  end
end
