# frozen_string_literal: true

require "test_helper"

class ListSessionPresentationsToolTest < ActiveSupport::TestCase
  test "returns presentations for meeting and group" do
    response = ListSessionPresentationsTool.call(
      server_context: {}, meeting_number: "124", group_acronym: "tls"
    )
    result = JSON.parse(response.content.first[:text])

    assert_equal 3, result.size
  end

  test "presentations are ordered by order field" do
    response = ListSessionPresentationsTool.call(
      server_context: {}, meeting_number: "124", group_acronym: "tls"
    )
    result = JSON.parse(response.content.first[:text])
    orders = result.map { |p| p["order"] }

    assert_equal orders.sort, orders
  end

  test "includes document details" do
    response = ListSessionPresentationsTool.call(
      server_context: {}, meeting_number: "124", group_acronym: "tls"
    )
    result = JSON.parse(response.content.first[:text])
    doc_names = result.map { |p| p["document"]["name"] }

    assert_includes doc_names, "slides-124-tls-chairs"
    assert_includes doc_names, "agenda-124-tls"
    assert_includes doc_names, "minutes-124-tls"
  end

  test "includes file availability in document details" do
    response = ListSessionPresentationsTool.call(
      server_context: {}, meeting_number: "124", group_acronym: "tls"
    )
    result = JSON.parse(response.content.first[:text])
    presentation = result.first

    assert_includes presentation["document"].keys, "file_available"
    assert_includes presentation["document"].keys, "file_download_status"
    assert_equal false, presentation["document"]["file_available"]
  end

  test "returns error for non-existent meeting" do
    response = ListSessionPresentationsTool.call(
      server_context: {}, meeting_number: "999", group_acronym: "tls"
    )

    assert response.error?
    assert_includes response.content.first[:text], "Meeting"
    assert_includes response.content.first[:text], "not found"
  end

  test "returns error for non-existent group" do
    response = ListSessionPresentationsTool.call(
      server_context: {}, meeting_number: "124", group_acronym: "nonexistent"
    )

    assert response.error?
    assert_includes response.content.first[:text], "Group"
    assert_includes response.content.first[:text], "not found"
  end

  test "returns empty array when no presentations exist" do
    response = ListSessionPresentationsTool.call(
      server_context: {}, meeting_number: "124", group_acronym: "quic"
    )
    result = JSON.parse(response.content.first[:text])

    assert_equal [], result
  end
end
