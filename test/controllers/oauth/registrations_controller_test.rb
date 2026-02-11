# frozen_string_literal: true

require "test_helper"

module Oauth
  class RegistrationsControllerTest < ActionDispatch::IntegrationTest
    test "registers a non-confidential client" do
      assert_difference "Doorkeeper::Application.count", 1 do
        post "/oauth/register",
          params: {
            client_name: "My MCP Client",
            redirect_uris: [ "https://example.com/callback" ],
            token_endpoint_auth_method: "none",
            scope: "mcp"
          }.to_json,
          headers: { "Content-Type" => "application/json" }
      end

      assert_response :created
      body = JSON.parse(response.body)

      assert body["client_id"].present?
      assert_nil body["client_secret"]
      assert_equal "My MCP Client", body["client_name"]
      assert_equal [ "https://example.com/callback" ], body["redirect_uris"]
      assert_equal "none", body["token_endpoint_auth_method"]
      assert_equal "mcp", body["scope"]
    end

    test "registers a confidential client with secret" do
      post "/oauth/register",
        params: {
          client_name: "Confidential Client",
          redirect_uris: [ "https://example.com/callback" ],
          token_endpoint_auth_method: "client_secret_post",
          scope: "mcp"
        }.to_json,
        headers: { "Content-Type" => "application/json" }

      assert_response :created
      body = JSON.parse(response.body)

      assert body["client_id"].present?
      assert body["client_secret"].present?
      assert_equal "client_secret_post", body["token_endpoint_auth_method"]
    end

    test "defaults to non-confidential when token_endpoint_auth_method is omitted" do
      post "/oauth/register",
        params: {
          client_name: "Default Client",
          redirect_uris: [ "https://example.com/callback" ]
        }.to_json,
        headers: { "Content-Type" => "application/json" }

      assert_response :created
      body = JSON.parse(response.body)
      assert_equal "none", body["token_endpoint_auth_method"]
      assert_nil body["client_secret"]
    end

    test "returns error when redirect_uris is missing" do
      post "/oauth/register",
        params: { client_name: "Bad Client" }.to_json,
        headers: { "Content-Type" => "application/json" }

      assert_response :bad_request
      body = JSON.parse(response.body)
      assert_equal "invalid_client_metadata", body["error"]
      assert_match(/redirect_uris/, body["error_description"])
    end

    test "returns error when redirect_uris is empty" do
      post "/oauth/register",
        params: {
          client_name: "Bad Client",
          redirect_uris: []
        }.to_json,
        headers: { "Content-Type" => "application/json" }

      assert_response :bad_request
      body = JSON.parse(response.body)
      assert_equal "invalid_client_metadata", body["error"]
    end

    test "supports multiple redirect URIs" do
      post "/oauth/register",
        params: {
          client_name: "Multi Redirect Client",
          redirect_uris: [ "https://example.com/callback", "https://example.com/alt-callback" ]
        }.to_json,
        headers: { "Content-Type" => "application/json" }

      assert_response :created
      body = JSON.parse(response.body)
      assert_equal 2, body["redirect_uris"].length
    end

    test "uses default name when client_name is not provided" do
      post "/oauth/register",
        params: {
          redirect_uris: [ "https://example.com/callback" ]
        }.to_json,
        headers: { "Content-Type" => "application/json" }

      assert_response :created
      body = JSON.parse(response.body)
      assert_equal "Unknown Client", body["client_name"]
    end

    test "does not require authentication" do
      post "/oauth/register",
        params: {
          client_name: "Test Client",
          redirect_uris: [ "https://example.com/callback" ]
        }.to_json,
        headers: { "Content-Type" => "application/json" }

      assert_response :created
    end
  end
end
