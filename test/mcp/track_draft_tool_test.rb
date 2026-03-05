# frozen_string_literal: true

require "test_helper"

class TrackDraftToolTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @user = users(:alice)
    @server_context = { user: @user }
  end

  test "tracks a new draft" do
    response = TrackDraftTool.call(
      server_context: @server_context,
      draft_name: "draft-ietf-httpbis-http2bis",
      action: "track"
    )
    result = JSON.parse(response.content.first[:text])

    assert_equal "Now tracking", result["message"]
    assert_equal "draft-ietf-httpbis-http2bis", result["draft_name"]
    assert_equal "active", result["status"]
    assert TrackedDraft.exists?(draft_name: "draft-ietf-httpbis-http2bis")
  end

  test "enqueues check job when tracking" do
    assert_enqueued_with(job: CheckDraftUpdatesJob, args: [ "draft-ietf-httpbis-http2bis" ]) do
      TrackDraftTool.call(
        server_context: @server_context,
        draft_name: "draft-ietf-httpbis-http2bis",
        action: "track"
      )
    end
  end

  test "returns already tracking for existing active draft" do
    response = TrackDraftTool.call(
      server_context: @server_context,
      draft_name: "draft-ietf-tls-esni",
      action: "track"
    )
    result = JSON.parse(response.content.first[:text])

    assert_equal "Already tracking", result["message"]
  end

  test "reactivates archived draft" do
    response = TrackDraftTool.call(
      server_context: @server_context,
      draft_name: "draft-ietf-quic-transport",
      action: "track"
    )
    result = JSON.parse(response.content.first[:text])

    assert_equal "Now tracking", result["message"]
    assert_equal "active", result["status"]
  end

  test "untracks a tracked draft" do
    response = TrackDraftTool.call(
      server_context: @server_context,
      draft_name: "draft-ietf-tls-esni",
      action: "untrack"
    )
    result = JSON.parse(response.content.first[:text])

    assert_equal "Stopped tracking", result["message"]
    assert_equal "archived", result["status"]
  end

  test "returns error when untracking nonexistent draft" do
    response = TrackDraftTool.call(
      server_context: @server_context,
      draft_name: "draft-nonexistent",
      action: "untrack"
    )

    assert response.error?
    assert_includes response.content.first[:text], "Not tracking"
  end
end
