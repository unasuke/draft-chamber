# frozen_string_literal: true

require "test_helper"

class DatatrackerImportJobTest < ActiveJob::TestCase
  MockResponse = Struct.new(:status, :headers, :body, keyword_init: true)

  class TestJob < ApplicationJob
    include DatatrackerImportJob

    attr_accessor :error_to_raise

    def perform
      raise error_to_raise if error_to_raise
    end
  end

  test "logs response headers and body on APIError" do
    response = MockResponse.new(
      status: 403,
      headers: { "retry-after" => "120", "content-type" => "text/html" },
      body: "Rate limit exceeded"
    )
    error = Datatracker::ForbiddenError.new(response: response)

    job = TestJob.new
    job.error_to_raise = error

    assert_raises(Datatracker::ForbiddenError) do
      job.perform_now
    end
  end

  test "re-raises the original error after logging" do
    response = MockResponse.new(status: 403, headers: {}, body: "Forbidden")
    error = Datatracker::ForbiddenError.new(response: response)

    job = TestJob.new
    job.error_to_raise = error

    raised = assert_raises(Datatracker::ForbiddenError) do
      job.perform_now
    end

    assert_equal "Forbidden (403)", raised.message
  end

  test "retries in a minute on ThrottleError" do
    job = TestJob.new
    job.error_to_raise = Datatracker::ThrottleError.new("Failed to record the next datatracker request slot")

    freeze_time do
      job.perform_now

      # retry_on adds up to 15% jitter to the wait
      scheduled_at = enqueued_jobs.last[:at]
      assert_operator scheduled_at, :>=, 1.minute.from_now.to_f
      assert_operator scheduled_at, :<=, (1.minute * 1.15).from_now.to_f
    end
  end
end
