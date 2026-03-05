# frozen_string_literal: true

require "test_helper"

class CheckTrackedDraftsJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "enqueues CheckDraftUpdatesJob for each active tracked draft" do
    assert_enqueued_with(job: CheckDraftUpdatesJob, args: [ "draft-ietf-tls-esni" ]) do
      CheckTrackedDraftsJob.perform_now
    end
  end

  test "does not enqueue jobs for archived tracked drafts" do
    assert_enqueued_jobs 1, only: CheckDraftUpdatesJob do
      CheckTrackedDraftsJob.perform_now
    end
  end
end
