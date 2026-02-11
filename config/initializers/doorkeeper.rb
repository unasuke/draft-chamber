# frozen_string_literal: true

Doorkeeper.configure do
  orm :active_record

  # Authenticate resource owner via GitHub session
  resource_owner_authenticator do
    User.find_by(id: session[:user_id]) || redirect_to(login_path)
  end

  # OAuth 2.1: Only authorization_code grant (implicit/password removed)
  grant_flows %w[authorization_code]

  # OAuth 2.1: Require PKCE for non-confidential clients
  force_pkce

  # OAuth 2.1: Only S256 challenge method
  pkce_code_challenge_methods %w[S256]

  # OAuth 2.1: Enforce PKCE for all clients including confidential
  # force_pkce only applies to non-confidential clients, so we use
  # before_successful_authorization to enforce PKCE for all clients
  before_successful_authorization do |controller, context|
    if context.pre_auth.code_challenge.blank?
      context.pre_auth.error = :invalid_request
      context.pre_auth.missing_param = :code_challenge
    end
  end

  # Security: Hash tokens and application secrets
  hash_token_secrets
  hash_application_secrets

  # OAuth 2.1: Enable refresh tokens with rotation (do not reuse)
  use_refresh_token

  # Access token expiration: 1 hour
  access_token_expires_in 1.hour

  # Enforce Content-Type on token requests
  enforce_content_type

  # Only accept tokens via Authorization header (not query params)
  access_token_methods :from_bearer_authorization

  # Default scope for MCP access
  default_scopes :mcp
end
