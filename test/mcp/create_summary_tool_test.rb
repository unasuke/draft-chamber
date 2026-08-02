# frozen_string_literal: true

require "test_helper"

class CreateSummaryToolTest < ActiveSupport::TestCase
  setup do
    @user = users(:alice)
    @server_context = { user: @user }
  end

  def create_summary(**params)
    CreateSummaryTool.call(
      server_context: @server_context,
      **{ session_id: sessions(:tls_at_124).datatracker_id, title: "TLS WG", body: "# TLS WG" }.merge(params)
    )
  end

  test "saves a summary for the session" do
    assert_difference "Summary.count", 1 do
      create_summary
    end

    summary = Summary.order(:id).last
    assert_equal sessions(:tls_at_124), summary.session
    assert_equal @user, summary.user
    assert_equal "124", summary.meeting_number
    assert_equal "tls", summary.group_acronym
  end

  test "returns the shareable url and token" do
    response = create_summary
    result = JSON.parse(response.content.first[:text])

    summary = Summary.order(:id).last
    assert_equal summary.public_token, result["public_token"]
    assert_equal summary.public_url, result["url"]
    assert_equal sessions(:tls_at_124).datatracker_id, result["session_id"]
    assert_equal "124", result["meeting_number"]
    assert_equal "tls", result["group"]
  end

  test "records the oauth application as the generating client" do
    application = Doorkeeper::Application.create!(
      name: "Claude Code",
      redirect_uri: "https://example.invalid/callback",
      confidential: false,
      scopes: "mcp"
    )

    CreateSummaryTool.call(
      server_context: { user: @user, oauth_application: application },
      session_id: sessions(:tls_at_124).datatracker_id,
      title: "TLS WG",
      body: "# TLS WG"
    )

    summary = Summary.order(:id).last
    assert_equal application, summary.oauth_application
    assert_equal "Claude Code", summary.client_name
  end

  test "falls back to unknown when no oauth application is present" do
    create_summary

    assert_equal "unknown", Summary.order(:id).last.client_name
  end

  test "creates a new summary on every call" do
    assert_difference "Summary.count", 2 do
      create_summary
      create_summary
    end
  end

  test "returns session_not_found for an unknown session" do
    response = create_summary(session_id: 99_999_999)
    result = JSON.parse(response.content.first[:text])

    assert response.error?
    assert_equal "session_not_found", result["error"]
    assert_includes result["message"], "99999999"
  end

  test "returns validation_failed for a blank title" do
    response = create_summary(title: "")
    result = JSON.parse(response.content.first[:text])

    assert response.error?
    assert_equal "validation_failed", result["error"]
    assert_includes result["message"], "Title"
  end

  test "returns validation_failed for a blank body" do
    response = create_summary(body: "")
    result = JSON.parse(response.content.first[:text])

    assert response.error?
    assert_equal "validation_failed", result["error"]
    assert_includes result["message"], "Body"
  end

  test "exposes structured_content on success" do
    response = create_summary

    assert_kind_of Hash, response.structured_content
    assert_equal "TLS WG", response.structured_content[:title]
  end
end
