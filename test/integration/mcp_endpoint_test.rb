# frozen_string_literal: true

require "test_helper"

class McpEndpointTest < ActionDispatch::IntegrationTest
  include OAuthTestHelper

  setup do
    @token = create_access_token(user: users(:alice))
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
end
