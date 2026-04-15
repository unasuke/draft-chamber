# frozen_string_literal: true

require "test_helper"

class ListSessionsToolTest < ActiveSupport::TestCase
  test "returns sessions for a meeting" do
    response = ListSessionsTool.call(server_context: {}, meeting_number: "124")
    result = JSON.parse(response.content.first[:text])

    assert_equal 2, result["sessions"].size
  end

  test "filters by group_acronym" do
    response = ListSessionsTool.call(server_context: {}, meeting_number: "124", group_acronym: "tls")
    result = JSON.parse(response.content.first[:text])

    assert_equal 1, result["sessions"].size
    assert_equal "tls", result["sessions"].first["group"]
  end

  test "returns expected session fields" do
    response = ListSessionsTool.call(server_context: {}, meeting_number: "124", group_acronym: "tls")
    result = JSON.parse(response.content.first[:text])
    session = result["sessions"].first

    assert_equal 34365, session["id"]
    assert_equal "tls", session["name"]
    assert_equal "Transport Layer Security", session["group_name"]
    assert_equal "regular", session["purpose"]
    assert_equal "2:00:00", session["requested_duration"]
    assert session["on_agenda"]
  end

  test "returns error for non-existent meeting" do
    response = ListSessionsTool.call(server_context: {}, meeting_number: "999")

    assert response.error?
    assert_includes response.content.first[:text], "not found"
  end

  test "returns empty array when no sessions match group filter" do
    response = ListSessionsTool.call(server_context: {}, meeting_number: "124", group_acronym: "nonexistent")
    result = JSON.parse(response.content.first[:text])

    assert_equal [], result["sessions"]
  end

  test "exposes structured_content with symbol-keyed data" do
    response = ListSessionsTool.call(server_context: {}, meeting_number: "124", group_acronym: "tls")

    assert_kind_of Hash, response.structured_content
    assert_equal 1, response.structured_content[:sessions].size
    assert_equal "tls", response.structured_content[:sessions].first[:group]
  end
end
