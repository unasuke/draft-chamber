# frozen_string_literal: true

module DatatrackerImport
  class DocumentImporter < BaseImporter
    def import(document_uris:)
      log("Importing #{document_uris.size} documents...")

      document_uris.each do |uri|
        next if Document.exists?(resource_uri: uri)

        doc_name = uri.split("/").compact_blank.last

        begin
          response = client.documents.find_by_name(doc_name)
          obj = response.objects.first
          next unless obj

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
        rescue Datatracker::NotFoundError
          log("Document not found: #{doc_name}")
          @stats[:errors] += 1
        rescue Datatracker::RateLimitError
          log("Rate limited, sleeping 5s...")
          sleep(5)
          retry
        end
      end

      log("Documents import complete: #{stats}")
      stats
    end
  end
end
