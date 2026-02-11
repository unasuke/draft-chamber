# frozen_string_literal: true

class McpApp
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

    transport.handle_request(request)
  end

  private

  def extract_bearer_token(request)
    auth_header = request.get_header("HTTP_AUTHORIZATION")
    return nil unless auth_header

    match = auth_header.match(/\ABearer\s+(.+)\z/i)
    match&.[](1)
  end

  def unauthorized_response(request)
    resource_metadata_url = "#{request.base_url}/.well-known/oauth-protected-resource"
    [
      401,
      {
        "Content-Type" => "application/json",
        "WWW-Authenticate" => %(Bearer resource_metadata="#{resource_metadata_url}")
      },
      [ { error: "unauthorized", error_description: "Valid Bearer token required" }.to_json ]
    ]
  end

  def transport
    @transport ||= begin
      server = MCP::Server.new(
        name: "draft-chamber",
        version: "0.1.0",
        tools: [ ListMeetingsTool, GetMeetingTool, ListSessionsTool, GetSessionDetailTool,
                 ListSessionPresentationsTool, GetSessionPresentationTool, ReadDocumentMaterialTool ],
        resource_templates: DocumentMaterialResource.resource_templates
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
end
