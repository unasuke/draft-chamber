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
end
