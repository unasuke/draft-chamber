# frozen_string_literal: true

class McpApp
  def call(env)
    request = Rack::Request.new(env)
    transport.handle_request(request)
  end

  private

  def transport
    @transport ||= begin
      server = MCP::Server.new(
        name: "draft-chamber",
        version: "0.1.0",
        tools: [ ListMeetingsTool ]
      )
      transport = MCP::Server::Transports::StreamableHTTPTransport.new(server, stateless: true)
      server.transport = transport
      transport
    end
  end
end
