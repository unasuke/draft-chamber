# frozen_string_literal: true

require "test_helper"

class McpAuthTest < ActionDispatch::IntegrationTest
  include OAuthTestHelper

  # --- 401 Unauthorized tests ---

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
    token = create_access_token(user: users(:alice), resource: "http://www.example.com/mcp")
    Doorkeeper::AccessToken.last.update_column(:expires_in, 0)

    post "/mcp",
      params: { jsonrpc: "2.0", id: 1, method: "initialize" }.to_json,
      headers: bearer_headers(token)

    assert_response :unauthorized
  end

  # --- WWW-Authenticate header tests ---

  test "401 WWW-Authenticate header includes resource_metadata and scope" do
    post "/mcp",
      params: { jsonrpc: "2.0", id: 1, method: "initialize" }.to_json,
      headers: { "Content-Type" => "application/json", "Accept" => "application/json, text/event-stream" }

    assert_response :unauthorized
    www_auth = response.headers["WWW-Authenticate"]
    assert_match(/Bearer/, www_auth)
    assert_match(%r{resource_metadata="https?://[^"]+/\.well-known/oauth-protected-resource"}, www_auth)
    assert_match(/scope="mcp"/, www_auth)
  end

  # --- 403 Forbidden tests (V5: insufficient scope) ---

  test "returns 403 with valid token but insufficient scope" do
    token = create_access_token(user: users(:alice), scopes: "other", resource: "http://www.example.com/mcp")

    post "/mcp",
      params: { jsonrpc: "2.0", id: 1, method: "initialize" }.to_json,
      headers: bearer_headers(token)

    assert_response :forbidden

    body = JSON.parse(response.body)
    assert_equal "forbidden", body["error"]
    assert_equal "Insufficient scope", body["error_description"]
  end

  test "403 WWW-Authenticate header includes insufficient_scope error and scope" do
    token = create_access_token(user: users(:alice), scopes: "other", resource: "http://www.example.com/mcp")

    post "/mcp",
      params: { jsonrpc: "2.0", id: 1, method: "initialize" }.to_json,
      headers: bearer_headers(token)

    assert_response :forbidden
    www_auth = response.headers["WWW-Authenticate"]
    assert_match(/error="insufficient_scope"/, www_auth)
    assert_match(/scope="mcp"/, www_auth)
    assert_match(%r{resource_metadata="https?://[^"]+/\.well-known/oauth-protected-resource"}, www_auth)
  end

  # --- RFC 8707 audience validation tests (V2) ---

  test "returns success with token bound to correct resource" do
    token = create_access_token(
      user: users(:alice),
      resource: "http://www.example.com/mcp"
    )

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

  test "returns 401 with token bound to different resource" do
    token = create_access_token(
      user: users(:alice),
      resource: "https://other-server.example.com/mcp"
    )

    post "/mcp",
      params: { jsonrpc: "2.0", id: 1, method: "initialize" }.to_json,
      headers: bearer_headers(token)

    assert_response :unauthorized
  end

  test "returns 401 with token without resource claim" do
    token = create_access_token(user: users(:alice), resource: nil)

    post "/mcp",
      params: { jsonrpc: "2.0", id: 1, method: "initialize" }.to_json,
      headers: bearer_headers(token)

    assert_response :unauthorized
  end
end
