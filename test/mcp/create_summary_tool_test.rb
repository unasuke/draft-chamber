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
      **{ meeting_number: "124", group_acronym: "tls", title: "TLS WG", body: "# TLS WG" }.merge(params)
    )
  end

  test "saves a summary for the meeting and group" do
    assert_difference "Summary.count", 1 do
      create_summary
    end

    summary = Summary.order(:id).last
    assert_equal meetings(:ietf124), summary.meeting
    assert_equal groups(:tls), summary.group
    assert_equal @user, summary.user
    assert_equal "124", summary.meeting_number
    assert_equal "tls", summary.group_acronym
  end

  test "saves a summary without a group" do
    create_summary(group_acronym: nil)

    summary = Summary.order(:id).last
    assert_nil summary.group
    assert_nil summary.group_acronym
    assert_equal meetings(:ietf124), summary.meeting
  end

  test "returns the shareable url and token" do
    response = create_summary
    result = JSON.parse(response.content.first[:text])

    summary = Summary.order(:id).last
    assert_equal summary.public_token, result["public_token"]
    assert_equal summary.public_url, result["url"]
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
      meeting_number: "124",
      group_acronym: "tls",
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

  test "returns meeting_not_found for an unknown meeting" do
    response = create_summary(meeting_number: "9999")
    result = JSON.parse(response.content.first[:text])

    assert response.error?
    assert_equal "meeting_not_found", result["error"]
    assert_includes result["message"], "9999"
  end

  test "returns group_not_found for an unknown group" do
    response = create_summary(group_acronym: "nosuchwg")
    result = JSON.parse(response.content.first[:text])

    assert response.error?
    assert_equal "group_not_found", result["error"]
    assert_includes result["message"], "nosuchwg"
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
