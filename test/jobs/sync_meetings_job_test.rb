# frozen_string_literal: true

require "test_helper"

class SyncMeetingsJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "enqueues SyncMeetingDataJob for each syncable meeting" do
    travel_to Date.new(2025, 11, 15) do
      assert_enqueued_with(job: SyncMeetingDataJob, args: [ "124" ]) do
        SyncMeetingsJob.perform_now
      end
    end
  end

  test "does not enqueue jobs for old meetings" do
    travel_to Date.new(2026, 6, 1) do
      assert_no_enqueued_jobs(only: SyncMeetingDataJob) do
        SyncMeetingsJob.perform_now
      end
    end
  end
end
