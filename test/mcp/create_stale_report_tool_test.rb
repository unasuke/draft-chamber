# frozen_string_literal: true

require "test_helper"

class CreateStaleReportToolTest < ActiveSupport::TestCase
  setup do
    @user = users(:alice)
    @server_context = { user: @user }
  end

  test "reports a meeting as stale" do
    response = CreateStaleReportTool.call(
      server_context: @server_context,
      reportable_type: "Meeting",
      reportable_identifier: "124"
    )
    result = JSON.parse(response.content.first[:text])

    assert_equal "pending", result["status"]
    assert_equal "Meeting", result["reportable_type"]
    assert_equal meetings(:ietf124).id, result["reportable_id"]
  end

  test "reports a document as stale" do
    response = CreateStaleReportTool.call(
      server_context: @server_context,
      reportable_type: "Document",
      reportable_identifier: "slides-124-tls-chairs"
    )
    result = JSON.parse(response.content.first[:text])

    assert_equal "pending", result["status"]
    assert_equal "Document", result["reportable_type"]
    assert_equal documents(:tls_chairs_slides).id, result["reportable_id"]
  end

  test "reports a group as stale" do
    response = CreateStaleReportTool.call(
      server_context: @server_context,
      reportable_type: "Group",
      reportable_identifier: "tls"
    )
    result = JSON.parse(response.content.first[:text])

    assert_equal "pending", result["status"]
    assert_equal "Group", result["reportable_type"]
    assert_equal groups(:tls).id, result["reportable_id"]
  end

  test "includes message in report" do
    response = CreateStaleReportTool.call(
      server_context: @server_context,
      reportable_type: "Meeting",
      reportable_identifier: "124",
      message: "Agenda is outdated"
    )
    result = JSON.parse(response.content.first[:text])

    assert_equal "Agenda is outdated", result["message"]
  end

  test "returns error for nonexistent resource" do
    response = CreateStaleReportTool.call(
      server_context: @server_context,
      reportable_type: "Meeting",
      reportable_identifier: "999"
    )

    assert response.error?
    assert_includes response.content.first[:text], "Resource not found"
  end

  test "returns error for duplicate pending report" do
    CreateStaleReportTool.call(
      server_context: @server_context,
      reportable_type: "Meeting",
      reportable_identifier: "124"
    )

    response = CreateStaleReportTool.call(
      server_context: @server_context,
      reportable_type: "Meeting",
      reportable_identifier: "124"
    )

    assert response.error?
    assert_includes response.content.first[:text], "already reported"
  end

  test "exposes structured_content with symbol-keyed data" do
    response = CreateStaleReportTool.call(
      server_context: @server_context,
      reportable_type: "Meeting",
      reportable_identifier: "124"
    )

    assert_kind_of Hash, response.structured_content
    assert_equal "pending", response.structured_content[:status]
    assert_equal "Meeting", response.structured_content[:reportable_type]
  end
end
