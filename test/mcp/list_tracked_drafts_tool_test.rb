# frozen_string_literal: true

require "test_helper"

class ListTrackedDraftsToolTest < ActiveSupport::TestCase
  setup do
    @user = users(:alice)
    @server_context = { user: @user }
  end

  test "lists active tracked drafts" do
    response = ListTrackedDraftsTool.call(
      server_context: @server_context
    )
    result = JSON.parse(response.content.first[:text])

    assert_equal 1, result.size
    assert_equal "draft-ietf-tls-esni", result.first["draft_name"]
    assert_equal "active", result.first["status"]
    assert_equal "22", result.first["last_known_rev"]
  end

  test "includes document info when available" do
    response = ListTrackedDraftsTool.call(
      server_context: @server_context
    )
    result = JSON.parse(response.content.first[:text])

    draft = result.find { |d| d["draft_name"] == "draft-ietf-tls-esni" }
    assert_equal "TLS Encrypted Client Hello", draft["title"]
    assert_equal "tls", draft["group"]
  end

  test "includes archived drafts when requested" do
    response = ListTrackedDraftsTool.call(
      server_context: @server_context,
      include_archived: true
    )
    result = JSON.parse(response.content.first[:text])

    assert_equal 2, result.size
    statuses = result.map { |d| d["status"] }
    assert_includes statuses, "active"
    assert_includes statuses, "archived"
  end

  test "returns empty array when no tracked drafts" do
    TrackedDraft.delete_all

    response = ListTrackedDraftsTool.call(
      server_context: @server_context
    )
    result = JSON.parse(response.content.first[:text])

    assert_equal [], result
  end
end
