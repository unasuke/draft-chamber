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
end
