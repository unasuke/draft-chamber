# frozen_string_literal: true

require "test_helper"

class GetMeetingToolTest < ActiveSupport::TestCase
  test "returns meeting details with sessions" do
    response = GetMeetingTool.call(server_context: {}, number: "124")
    result = JSON.parse(response.content.first[:text])

    assert_equal "124", result["number"]
    assert_equal "ietf", result["type"]
    assert_equal "Montreal", result["city"]
    assert_equal 2, result["sessions"].size
  end

  test "includes session group information" do
    response = GetMeetingTool.call(server_context: {}, number: "124")
    result = JSON.parse(response.content.first[:text])
    session_names = result["sessions"].map { |s| s["group"] }

    assert_includes session_names, "tls"
    assert_includes session_names, "quic"
  end

  test "returns error for non-existent meeting" do
    response = GetMeetingTool.call(server_context: {}, number: "999")

    assert response.error?
    assert_includes response.content.first[:text], "not found"
  end

  test "exposes structured_content with symbol-keyed data" do
    response = GetMeetingTool.call(server_context: {}, number: "124")

    assert_kind_of Hash, response.structured_content
    assert_equal "124", response.structured_content[:number]
    assert_equal 2, response.structured_content[:sessions].size
  end
end
