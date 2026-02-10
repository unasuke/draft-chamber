# frozen_string_literal: true

module DatatrackerImport
  class MeetingImporter < BaseImporter
    def import(params = {})
      log("Importing meetings...")

      objects = fetch_all_pages(client.meetings, params)
      log("Fetched #{objects.size} meetings from API")

      objects.each do |obj|
        upsert_record(Meeting, resource_uri: obj["resource_uri"], attributes: {
          number: obj["number"],
          meeting_type: extract_name_from_uri(obj["type"]),
          date: obj["date"],
          days: obj["days"],
          city: obj["city"],
          country: obj["country"],
          time_zone: obj["time_zone"],
          venue_name: obj["venue_name"],
          attendees: obj["attendees"]
        })
      end

      log("Meetings import complete: #{stats}")
      stats
    end
  end
end
