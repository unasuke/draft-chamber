# frozen_string_literal: true

require "test_helper"

class GetSummaryToolTest < ActiveSupport::TestCase
  setup do
    @user = users(:alice)
    @server_context = { user: @user }
  end

  def get_summary(token)
    GetSummaryTool.call(server_context: @server_context, public_token: token)
  end

  test "returns the summary with its body" do
    summary = summaries(:tls_124_by_alice)
    result = JSON.parse(get_summary(summary.public_token).content.first[:text])

    assert_equal summary.public_token, result["public_token"]
    assert_equal summary.title, result["title"]
    assert_equal summary.body, result["body"]
    assert_equal summary.public_url, result["url"]
    assert_equal "Claude Code", result["client_name"]
    assert_equal sessions(:tls_at_124).datatracker_id, result["session_id"]
  end

  test "returns an orphaned summary with a null session_id" do
    summary = summaries(:orphaned)
    result = JSON.parse(get_summary(summary.public_token).content.first[:text])

    assert_equal summary.title, result["title"]
    assert_nil result["session_id"]
    assert_equal "124", result["meeting_number"]
  end

  test "returns summary_not_found for another users summary" do
    response = get_summary(summaries(:tls_124_by_bob).public_token)
    result = JSON.parse(response.content.first[:text])

    assert response.error?
    assert_equal "summary_not_found", result["error"]
  end

  test "returns summary_not_found for an unknown token" do
    response = get_summary("nosuchtoken000000000000x")
    result = JSON.parse(response.content.first[:text])

    assert response.error?
    assert_equal "summary_not_found", result["error"]
    assert_includes result["message"], "nosuchtoken"
  end

  test "exposes structured_content on success" do
    response = get_summary(summaries(:tls_124_by_alice).public_token)

    assert_kind_of Hash, response.structured_content
    assert_equal summaries(:tls_124_by_alice).title, response.structured_content[:title]
  end
end
