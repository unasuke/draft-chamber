# frozen_string_literal: true

require "test_helper"

class GetSessionDetailToolTest < ActiveSupport::TestCase
  test "returns session details with presentations" do
    response = GetSessionDetailTool.call(server_context: {}, session_id: 34365)
    result = JSON.parse(response.content.first[:text])

    assert_equal 34365, result["id"]
    assert_equal "tls", result["name"]
    assert_equal "124", result["meeting_number"]
    assert_equal "tls", result["group"]
    assert_equal "Transport Layer Security", result["group_name"]
    assert_equal 3, result["presentations"].size
  end

  test "presentations include document details" do
    response = GetSessionDetailTool.call(server_context: {}, session_id: 34365)
    result = JSON.parse(response.content.first[:text])
    doc_names = result["presentations"].map { |p| p["document"]["name"] }

    assert_includes doc_names, "slides-124-tls-chairs"
    assert_includes doc_names, "agenda-124-tls"
    assert_includes doc_names, "minutes-124-tls"
  end

  test "presentations are ordered" do
    response = GetSessionDetailTool.call(server_context: {}, session_id: 34365)
    result = JSON.parse(response.content.first[:text])
    orders = result["presentations"].map { |p| p["order"] }

    assert_equal orders.sort, orders
  end

  test "returns error for non-existent session" do
    response = GetSessionDetailTool.call(server_context: {}, session_id: 99999)

    assert response.error?
    assert_includes response.content.first[:text], "not found"
  end

  test "exposes structured_content with symbol-keyed data" do
    response = GetSessionDetailTool.call(server_context: {}, session_id: 34365)

    assert_kind_of Hash, response.structured_content
    assert_equal 34365, response.structured_content[:id]
    assert_equal 3, response.structured_content[:presentations].size
  end
end
