# frozen_string_literal: true

class SyncMeetingDataJob < ApplicationJob
  include DatatrackerImportJob

  def perform(meeting_number)
    Rails.logger.info("[SyncMeetingDataJob] Starting sync for meeting #{meeting_number}")

    client = Datatracker::Client.new

    session_stats = DatatrackerImport::SessionImporter
      .new(client: client)
      .import(meeting_number: meeting_number)

    presentation_stats = DatatrackerImport::SessionPresentationImporter
      .new(client: client)
      .import(meeting_number: meeting_number)

    Rails.logger.info(
      "[SyncMeetingDataJob] Meeting #{meeting_number} sync complete - " \
      "Sessions: #{session_stats}, Presentations: #{presentation_stats}"
    )
  end
end
