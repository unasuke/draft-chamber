# frozen_string_literal: true

module DatatrackerImport
  class FullImport
    attr_reader :client

    def initialize(client: nil)
      @client = client || Datatracker::Client.new
    end

    def import_meeting(meeting_number:, group_params: { state: "active", type: "wg" })
      results = {}

      results[:groups] = GroupImporter.new(client: client)
        .import(group_params)

      results[:meetings] = MeetingImporter.new(client: client)
        .import(number: meeting_number)

      results[:sessions] = SessionImporter.new(client: client)
        .import(meeting_number: meeting_number)

      results[:session_presentations] = SessionPresentationImporter.new(client: client)
        .import(meeting_number: meeting_number)

      results
    end
  end
end
