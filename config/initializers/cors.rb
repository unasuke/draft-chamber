# frozen_string_literal: true

# CORS configuration for browser-based MCP clients (e.g. MCP Inspector).
# These endpoints are either public metadata or protected by Bearer tokens,
# so origins "*" is safe (no cookie-based authentication).
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "*"

    # OAuth 2.0 discovery endpoints (RFC 8414, RFC 9728, OpenID Connect)
    resource "/.well-known/*",
      headers: :any,
      methods: [ :get, :options ]

    # OAuth 2.0 endpoints (registration, token, revocation, etc.)
    resource "/oauth/*",
      headers: :any,
      methods: [ :get, :post, :options ]

    # MCP endpoint (browser needs to read 401 WWW-Authenticate header for discovery)
    resource "/mcp",
      headers: :any,
      methods: [ :get, :post, :delete, :options ],
      expose: [ "mcp-session-id" ]
  end
end
