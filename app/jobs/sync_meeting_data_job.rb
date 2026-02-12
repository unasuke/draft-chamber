# frozen_string_literal: true

class SyncMeetingDataJob < ApplicationJob
  queue_as :default

  limits_concurrency to: 1, key: "datatracker_api_sync", duration: 5.minutes

  retry_on Datatracker::RateLimitError, wait: :polynomially_longer, attempts: 3
  retry_on Datatracker::ServerError, wait: 30.seconds, attempts: 3
  retry_on Faraday::TimeoutError, wait: 1.minute, attempts: 3
  retry_on Faraday::ConnectionFailed, wait: 1.minute, attempts: 3

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
