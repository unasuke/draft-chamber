# frozen_string_literal: true

module DatatrackerImport
  class SessionImporter < BaseImporter
    def import(meeting_number:)
      log("Importing sessions for meeting #{meeting_number}...")

      objects = fetch_all_pages(
        client.sessions,
        meeting__number: meeting_number
      )
      log("Fetched #{objects.size} sessions from API")

      objects.each do |obj|
        meeting = UriResolver.resolve_optional(obj["meeting"], Meeting)
        group = UriResolver.resolve_optional(obj["group"], Group)

        unless meeting
          log("Meeting not found for URI: #{obj["meeting"]}, skipping")
          @stats[:errors] += 1
          next
        end

        upsert_record(Session, resource_uri: obj["resource_uri"], attributes: {
          meeting: meeting,
          group: group,
          name: obj["name"],
          purpose: extract_name_from_uri(obj["purpose"]),
          requested_duration: obj["requested_duration"],
          on_agenda: obj["on_agenda"],
          remote_instructions: obj["remote_instructions"],
          attendees: obj["attendees"],
          datatracker_id: obj["id"]
        })
      end

      log("Sessions import complete: #{stats}")
      stats
    end
  end
end
