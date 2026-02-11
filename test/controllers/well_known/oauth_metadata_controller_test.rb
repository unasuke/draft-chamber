# frozen_string_literal: true

require "test_helper"

module WellKnown
  class OauthMetadataControllerTest < ActionDispatch::IntegrationTest
    test "protected_resource returns RFC 9728 metadata" do
      get "/.well-known/oauth-protected-resource"

      assert_response :success
      body = JSON.parse(response.body)

      assert_match %r{/mcp\z}, body["resource"]
      assert_kind_of Array, body["authorization_servers"]
      assert_equal 1, body["authorization_servers"].length
      assert_includes body["bearer_methods_supported"], "header"
      assert_includes body["scopes_supported"], "mcp"
    end

    test "authorization_server returns RFC 8414 metadata" do
      get "/.well-known/oauth-authorization-server"

      assert_response :success
      body = JSON.parse(response.body)

      assert body["issuer"].present?
      assert_match %r{/oauth/authorize\z}, body["authorization_endpoint"]
      assert_match %r{/oauth/token\z}, body["token_endpoint"]
      assert_match %r{/oauth/revoke\z}, body["revocation_endpoint"]
      assert_match %r{/oauth/introspect\z}, body["introspection_endpoint"]
      assert_match %r{/oauth/register\z}, body["registration_endpoint"]
      assert_includes body["response_types_supported"], "code"
      assert_includes body["grant_types_supported"], "authorization_code"
      assert_includes body["grant_types_supported"], "refresh_token"
      assert_includes body["token_endpoint_auth_methods_supported"], "client_secret_post"
      assert_includes body["token_endpoint_auth_methods_supported"], "none"
      assert_includes body["code_challenge_methods_supported"], "S256"
      assert_includes body["scopes_supported"], "mcp"
    end

    test "protected_resource does not require authentication" do
      get "/.well-known/oauth-protected-resource"
      assert_response :success
    end

    test "authorization_server does not require authentication" do
      get "/.well-known/oauth-authorization-server"
      assert_response :success
    end
  end
end
