# frozen_string_literal: true

require "test_helper"

class ListSummariesToolTest < ActiveSupport::TestCase
  setup do
    @user = users(:alice)
    @server_context = { user: @user }
  end

  def list(**params)
    response = ListSummariesTool.call(server_context: @server_context, **params)
    JSON.parse(response.content.first[:text])
  end

  test "returns only the callers own summaries" do
    titles = list["summaries"].map { |summary| summary["title"] }

    assert_includes titles, summaries(:tls_124_by_alice).title
    assert_not_includes titles, summaries(:tls_124_by_bob).title
  end

  test "excludes orphaned summaries" do
    titles = list["summaries"].map { |summary| summary["title"] }

    assert_not_includes titles, summaries(:orphaned).title
  end

  test "returns the total before limit and offset are applied" do
    result = list(limit: 1)

    assert_equal 1, result["summaries"].size
    assert_equal 2, result["total"]
  end

  test "does not include the body" do
    assert_not list["summaries"].first.key?("body")
  end

  test "includes the shareable url and client name" do
    entry = list["summaries"].find { |summary| summary["title"] == summaries(:tls_124_by_alice).title }

    assert_equal summaries(:tls_124_by_alice).public_url, entry["url"]
    assert_equal "Claude Code", entry["client_name"]
    assert_equal sessions(:tls_at_124).datatracker_id, entry["session_id"]
  end

  test "orders by created_at descending" do
    summaries(:tls_124_by_alice).update_column(:created_at, 1.day.ago)
    summaries(:tls_123_by_alice).update_column(:created_at, 2.days.ago)

    titles = list["summaries"].map { |summary| summary["title"] }

    assert_equal [ summaries(:tls_124_by_alice).title, summaries(:tls_123_by_alice).title ], titles
  end

  test "filters by session_id" do
    result = list(session_id: sessions(:tls_at_123).datatracker_id)

    assert_equal [ summaries(:tls_123_by_alice).title ], result["summaries"].map { |s| s["title"] }
    assert_equal 1, result["total"]
  end

  test "filters by meeting_number" do
    result = list(meeting_number: "123")

    assert_equal [ summaries(:tls_123_by_alice).title ], result["summaries"].map { |s| s["title"] }
  end

  test "filters by group_acronym" do
    result = list(group_acronym: "quic")

    assert_empty result["summaries"]
    assert_equal 0, result["total"]
  end

  test "clamps limit to the maximum" do
    assert_equal 2, list(limit: 101)["summaries"].size
  end

  test "clamps non positive limit to one" do
    assert_equal 1, list(limit: 0)["summaries"].size
  end

  test "applies offset" do
    summaries(:tls_124_by_alice).update_column(:created_at, 1.day.ago)
    summaries(:tls_123_by_alice).update_column(:created_at, 2.days.ago)

    result = list(offset: 1)

    assert_equal [ summaries(:tls_123_by_alice).title ], result["summaries"].map { |s| s["title"] }
    assert_equal 2, result["total"]
  end

  test "exposes structured_content" do
    response = ListSummariesTool.call(server_context: @server_context)

    assert_kind_of Hash, response.structured_content
    assert_equal 2, response.structured_content[:total]
  end
end
