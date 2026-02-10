# frozen_string_literal: true

module DatatrackerImport
  class SessionPresentationImporter < BaseImporter
    def import(meeting_number:, group_acronym: nil)
      log("Importing session presentations for meeting #{meeting_number}...")

      params = { session__meeting__number: meeting_number }
      params[:session__group__acronym] = group_acronym if group_acronym

      objects = fetch_all_pages(client.session_presentations, params)
      log("Fetched #{objects.size} session presentations from API")

      # Import referenced documents first
      document_uris = objects.map { |obj| obj["document"] }.compact.uniq
      DocumentImporter.new(client: client).import(document_uris: document_uris)

      # Create session presentation records
      objects.each do |obj|
        session = UriResolver.resolve_optional(obj["session"], Session)
        document = UriResolver.resolve_optional(obj["document"], Document)

        unless session
          log("Session not found for URI: #{obj["session"]}, skipping")
          @stats[:errors] += 1
          next
        end

        unless document
          log("Document not found for URI: #{obj["document"]}, skipping")
          @stats[:errors] += 1
          next
        end

        record = upsert_record(SessionPresentation,
          resource_uri: obj["resource_uri"],
          attributes: {
            session: session,
            document: document,
            order: obj["order"],
            rev: obj["rev"]
          }
        )

        if record && document.document_material.nil?
          document.create_document_material!(download_status: :pending)
          DownloadDocumentMaterialJob.perform_later(document.id, session.meeting.number)
        end
      end

      log("Session presentations import complete: #{stats}")
      stats
    end
  end
end
