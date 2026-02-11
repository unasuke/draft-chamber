# frozen_string_literal: true

require "test_helper"

class McpAuthTest < ActionDispatch::IntegrationTest
  include OAuthTestHelper

  test "returns 401 without Authorization header" do
    post "/mcp",
      params: { jsonrpc: "2.0", id: 1, method: "initialize" }.to_json,
      headers: { "Content-Type" => "application/json", "Accept" => "application/json, text/event-stream" }

    assert_response :unauthorized
    assert_equal "application/json", response.content_type

    body = JSON.parse(response.body)
    assert_equal "unauthorized", body["error"]
  end

  test "returns 401 with invalid Bearer token" do
    post "/mcp",
      params: { jsonrpc: "2.0", id: 1, method: "initialize" }.to_json,
      headers: bearer_headers("invalid-token-value")

    assert_response :unauthorized
  end

  test "returns 401 with expired token" do
    token = create_access_token(user: users(:alice))
    # Expire the token
    Doorkeeper::AccessToken.last.update_column(:expires_in, 0)

    post "/mcp",
      params: { jsonrpc: "2.0", id: 1, method: "initialize" }.to_json,
      headers: bearer_headers(token)

    assert_response :unauthorized
  end

  test "WWW-Authenticate header includes resource_metadata URL" do
    post "/mcp",
      params: { jsonrpc: "2.0", id: 1, method: "initialize" }.to_json,
      headers: { "Content-Type" => "application/json", "Accept" => "application/json, text/event-stream" }

    assert_response :unauthorized
    www_auth = response.headers["WWW-Authenticate"]
    assert_match(/Bearer/, www_auth)
    assert_match(%r{resource_metadata="https?://[^"]+/\.well-known/oauth-protected-resource"}, www_auth)
  end

  test "returns success with valid Bearer token" do
    token = create_access_token(user: users(:alice))

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
      headers: bearer_headers(token)

    assert_response :success
  end
end
