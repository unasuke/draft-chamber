# frozen_string_literal: true

class SyncMeetingsJob < ApplicationJob
  queue_as :default

  def perform
    meetings = Meeting.syncable
    Rails.logger.info("[SyncMeetingsJob] Enqueueing sync for #{meetings.count} meetings")

    meetings.find_each do |meeting|
      SyncMeetingDataJob.perform_later(meeting.number)
    end
  end
end
