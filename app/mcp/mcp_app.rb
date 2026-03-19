# frozen_string_literal: true

class McpApp
  REQUIRED_SCOPE = "mcp"
  TOOLS = [
    ListMeetingsTool, GetMeetingTool, ListSessionsTool, GetSessionDetailTool,
    ListSessionPresentationsTool, GetSessionPresentationTool, ReadDocumentMaterialTool,
    CreateStaleReportTool
  ].freeze

  def call(env)
    request = Rack::Request.new(env)

    token = extract_bearer_token(request)
    unless token
      return unauthorized_response(request)
    end

    access_token = Doorkeeper::AccessToken.by_token(token)
    unless access_token&.accessible?
      return unauthorized_response(request)
    end

    unless access_token.scopes.include?(REQUIRED_SCOPE)
      return forbidden_response(request)
    end

    # RFC 8707: Validate that the token was issued for this resource server.
    unless access_token.resource == resource_uri(request)
      return unauthorized_response(request)
    end

    user = User.find(access_token.resource_owner_id)
    build_transport(user: user).handle_request(request)
  end

  private

  def extract_bearer_token(request)
    auth_header = request.get_header("HTTP_AUTHORIZATION")
    return nil unless auth_header

    match = auth_header.match(/\ABearer\s+(.+)\z/i)
    match&.[](1)
  end

  def unauthorized_response(request)
    [
      401,
      {
        "Content-Type" => "application/json",
        "WWW-Authenticate" => www_authenticate_header(request)
      },
      [ { error: "unauthorized", error_description: "Valid Bearer token required" }.to_json ]
    ]
  end

  def forbidden_response(request)
    [
      403,
      {
        "Content-Type" => "application/json",
        "WWW-Authenticate" => www_authenticate_header(request, error: "insufficient_scope")
      },
      [ { error: "forbidden", error_description: "Insufficient scope" }.to_json ]
    ]
  end

  def public_base_url(request)
    if ENV["APP_HOST"].present?
      "https://#{ENV["APP_HOST"]}"
    else
      request.base_url
    end
  end

  def resource_uri(request)
    "#{public_base_url(request)}/mcp"
  end

  def www_authenticate_header(request, error: nil)
    resource_metadata_url = "#{public_base_url(request)}/.well-known/oauth-protected-resource"
    parts = [ %(Bearer resource_metadata="#{resource_metadata_url}") ]
    parts << %(error="#{error}") if error
    parts << %(scope="#{REQUIRED_SCOPE}")
    parts.join(", ")
  end

  def build_transport(user:)
    server = MCP::Server.new(
      name: "draft-chamber",
      version: "0.1.0",
      tools: TOOLS,
      resource_templates: DocumentMaterialResource.resource_templates,
      server_context: { user: user }
    )

    server.resources_list_handler do |params|
      DocumentMaterialResource.list_resources(params)
    end

    server.resources_read_handler do |params|
      DocumentMaterialResource.read_resource(params)
    end

    transport = MCP::Server::Transports::StreamableHTTPTransport.new(server, stateless: true)
    server.transport = transport
    transport
  end
end
