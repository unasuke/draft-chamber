# frozen_string_literal: true

module DatatrackerImport
  class DocumentImporter < BaseImporter
    BATCH_SIZE = 50

    def import(document_uris:)
      existing = Document.where(resource_uri: document_uris).pluck(:resource_uri).to_set
      names = document_uris.reject { existing.include?(it) }
        .map { it.split("/").compact_blank.last }
        .uniq
      log("Importing #{names.size} documents (#{existing.size} already exist)...")

      names.each_slice(BATCH_SIZE) do |batch|
        begin
          objects = client.documents.find_by_names(batch).objects
        rescue Datatracker::RateLimitError
          log("Rate limited, sleeping 5s...")
          sleep(5)
          retry
        end
        found = objects.to_h { [ it["name"], it ] }

        batch.each do |name|
          obj = found[name]
          unless obj
            log("Document not found: #{name}")
            @stats[:errors] += 1
            next
          end

          import_document(obj)
        end
      end

      log("Documents import complete: #{stats}")
      stats
    end

    private

    def import_document(obj)
      group = UriResolver.resolve_optional(obj["group"], Group)

      upsert_record(Document, resource_uri: obj["resource_uri"], attributes: {
        name: obj["name"],
        title: obj["title"],
        document_type: extract_name_from_uri(obj["type"]),
        abstract: obj["abstract"],
        rev: obj["rev"],
        pages: obj["pages"],
        uploaded_filename: obj["uploaded_filename"],
        group: group,
        time: obj["time"],
        expires: obj["expires"]
      })
    end
  end
end
