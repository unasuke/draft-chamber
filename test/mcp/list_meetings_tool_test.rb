# frozen_string_literal: true

require "test_helper"

class ListMeetingsToolTest < ActiveSupport::TestCase
  test "returns all meetings sorted by date descending" do
    response = ListMeetingsTool.call(server_context: {})
    result = JSON.parse(response.content.first[:text])

    assert_equal 3, result.size
    assert_equal "124", result.first["number"]
  end

  test "filters by meeting_type ietf" do
    response = ListMeetingsTool.call(server_context: {}, meeting_type: "ietf")
    result = JSON.parse(response.content.first[:text])

    assert_equal 2, result.size
    assert(result.all? { |m| m["type"] == "ietf" })
  end

  test "filters by meeting_type interim" do
    response = ListMeetingsTool.call(server_context: {}, meeting_type: "interim")
    result = JSON.parse(response.content.first[:text])

    assert_equal 1, result.size
    assert_equal "interim", result.first["type"]
  end

  test "respects limit parameter" do
    response = ListMeetingsTool.call(server_context: {}, limit: 1)
    result = JSON.parse(response.content.first[:text])

    assert_equal 1, result.size
  end

  test "returns expected meeting fields" do
    response = ListMeetingsTool.call(server_context: {}, limit: 1)
    result = JSON.parse(response.content.first[:text])
    meeting = result.first

    assert_equal "124", meeting["number"]
    assert_equal "ietf", meeting["type"]
    assert_equal "2025-11-01", meeting["date"]
    assert_equal "Montreal", meeting["city"]
    assert_equal "CA", meeting["country"]
    assert_equal "Palais des Congres", meeting["venue_name"]
    assert_equal 7, meeting["days"]
    assert_equal 1200, meeting["attendees"]
  end
end
