# frozen_string_literal: true

module WellKnown
  class OauthMetadataController < ApplicationController
    skip_before_action :require_login

    # RFC 9728: OAuth 2.0 Protected Resource Metadata
    # GET /.well-known/oauth-protected-resource
    def protected_resource
      render json: {
        resource: mcp_resource_uri,
        authorization_servers: [ authorization_server_issuer ],
        bearer_methods_supported: [ "header" ],
        scopes_supported: [ "mcp" ]
      }
    end

    # RFC 8414: OAuth 2.0 Authorization Server Metadata
    # GET /.well-known/oauth-authorization-server
    def authorization_server
      render json: {
        issuer: authorization_server_issuer,
        authorization_endpoint: "#{base_url}/oauth/authorize",
        token_endpoint: "#{base_url}/oauth/token",
        revocation_endpoint: "#{base_url}/oauth/revoke",
        introspection_endpoint: "#{base_url}/oauth/introspect",
        registration_endpoint: "#{base_url}/oauth/register",
        response_types_supported: [ "code" ],
        grant_types_supported: [ "authorization_code", "refresh_token" ],
        token_endpoint_auth_methods_supported: [ "client_secret_post", "none" ],
        code_challenge_methods_supported: [ "S256" ],
        scopes_supported: [ "mcp" ]
      }
    end

    private

    def base_url
      if ENV["APP_HOST"].present?
        "https://#{ENV["APP_HOST"]}"
      else
        request.base_url
      end
    end

    def mcp_resource_uri
      "#{base_url}/mcp"
    end

    def authorization_server_issuer
      base_url
    end
  end
end
