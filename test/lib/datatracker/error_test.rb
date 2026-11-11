# frozen_string_literal: true

require "test_helper"

class Datatracker::ErrorTest < ActiveSupport::TestCase
  MockResponse = Struct.new(:status, :headers, :body, keyword_init: true)

  test "ForbiddenError has correct default message" do
    response = MockResponse.new(status: 403, headers: {}, body: "")
    error = Datatracker::ForbiddenError.new(response: response)

    assert_equal "Forbidden (403)", error.message
    assert_equal 403, error.status
    assert_equal response, error.response
  end

  test "ForbiddenError accepts custom message" do
    response = MockResponse.new(status: 403, headers: {}, body: "")
    error = Datatracker::ForbiddenError.new("Custom message", response: response)

    assert_equal "Custom message", error.message
  end

  test "ForbiddenError is a subclass of APIError" do
    response = MockResponse.new(status: 403, headers: {}, body: "")
    error = Datatracker::ForbiddenError.new(response: response)

    assert_kind_of Datatracker::APIError, error
  end

  test "RateLimitError#retry_after parses delay seconds" do
    response = MockResponse.new(status: 429, headers: { "retry-after" => "120" }, body: "")

    assert_equal 120, Datatracker::RateLimitError.new(response: response).retry_after
  end

  test "RateLimitError#retry_after parses an HTTP-date" do
    freeze_time do
      response = MockResponse.new(status: 429, headers: { "retry-after" => 90.seconds.from_now.httpdate }, body: "")

      assert_equal 90, Datatracker::RateLimitError.new(response: response).retry_after
    end
  end

  test "RateLimitError#retry_after returns 0 for an HTTP-date in the past" do
    response = MockResponse.new(status: 429, headers: { "retry-after" => 1.hour.ago.httpdate }, body: "")

    assert_equal 0, Datatracker::RateLimitError.new(response: response).retry_after
  end

  test "RateLimitError#retry_after returns nil without the header" do
    response = MockResponse.new(status: 429, headers: {}, body: "")

    assert_nil Datatracker::RateLimitError.new(response: response).retry_after
    assert_nil Datatracker::RateLimitError.new(response: nil).retry_after
  end

  test "RateLimitError#retry_after returns nil for an unparseable value" do
    response = MockResponse.new(status: 429, headers: { "retry-after" => "soon" }, body: "")

    assert_nil Datatracker::RateLimitError.new(response: response).retry_after
  end
end
