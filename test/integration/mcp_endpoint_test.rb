# frozen_string_literal: true

require "test_helper"

class McpEndpointTest < ActionDispatch::IntegrationTest
  include OAuthTestHelper

  setup do
    @token = create_access_token(user: users(:alice), resource: "http://www.example.com/mcp")
  end

  test "initialize handshake returns server info" do
    post "/mcp",
      params: {
        jsonrpc: "2.0",
        id: 1,
        method: "initialize",
        params: {
          protocolVersion: "2025-03-26",
          capabilities: {},
          clientInfo: { name: "test", version: "1.0" }
        }
      }.to_json,
      headers: bearer_headers(@token)

    assert_response :success
  end

  test "tools/list includes list_meetings" do
    # First initialize
    post "/mcp",
      params: {
        jsonrpc: "2.0",
        id: 1,
        method: "initialize",
        params: {
          protocolVersion: "2025-03-26",
          capabilities: {},
          clientInfo: { name: "test", version: "1.0" }
        }
      }.to_json,
      headers: bearer_headers(@token)

    assert_response :success

    # Then list tools
    post "/mcp",
      params: {
        jsonrpc: "2.0",
        id: 2,
        method: "tools/list",
        params: {}
      }.to_json,
      headers: bearer_headers(@token)

    assert_response :success
  end

  test "tools/call create_stale_report_tool creates a stale report" do
    assert_difference "StaleReport.count", 1 do
      post "/mcp",
        params: {
          jsonrpc: "2.0",
          id: 1,
          method: "tools/call",
          params: {
            name: "create_stale_report_tool",
            arguments: {
              reportable_type: "Meeting",
              reportable_identifier: "124",
              message: "Data seems outdated"
            }
          }
        }.to_json,
        headers: bearer_headers(@token)
    end

    assert_response :success
    result = JSON.parse(response.body)
    content = JSON.parse(result.dig("result", "content", 0, "text"))
    assert_equal "pending", content["status"]
    assert_equal "Meeting", content["reportable_type"]
    assert_equal "Data seems outdated", content["message"]
  end
end
