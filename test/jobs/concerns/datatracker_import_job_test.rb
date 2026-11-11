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

  test "retries a 429 after Retry-After when it is longer than the base wait" do
    response = MockResponse.new(status: 429, headers: { "retry-after" => "900" }, body: "")
    job = TestJob.new
    job.error_to_raise = Datatracker::RateLimitError.new(response: response)

    freeze_time do
      assert_enqueued_with(job: TestJob, at: 900.seconds.from_now) do
        job.perform_now
      end
    end
  end

  test "retries a 429 after 5 minutes times the 429 count without Retry-After" do
    response = MockResponse.new(status: 429, headers: {}, body: "")
    job = TestJob.new
    job.error_to_raise = Datatracker::RateLimitError.new(response: response)
    job.exception_executions = { "[Datatracker::RateLimitError]" => 1 }

    freeze_time do
      assert_enqueued_with(job: TestJob, at: 10.minutes.from_now) do
        job.perform_now
      end
    end
  end

  test "counts 429s from 1 even after retries for other errors" do
    response = MockResponse.new(status: 429, headers: {}, body: "")
    job = TestJob.new
    job.error_to_raise = Datatracker::RateLimitError.new(response: response)
    job.executions = 2
    job.exception_executions = { "[Datatracker::ServerError]" => 2 }

    freeze_time do
      assert_enqueued_with(job: TestJob, at: 5.minutes.from_now) do
        job.perform_now
      end
    end
  end

  test "gives up on the third 429" do
    response = MockResponse.new(status: 429, headers: {}, body: "")
    job = TestJob.new
    job.error_to_raise = Datatracker::RateLimitError.new(response: response)
    job.exception_executions = { "[Datatracker::RateLimitError]" => 2 }

    assert_no_enqueued_jobs do
      assert_raises(Datatracker::RateLimitError) { job.perform_now }
    end
  end
end
