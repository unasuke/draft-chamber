# frozen_string_literal: true

class GetSummaryTool < MCP::Tool
  description <<~TEXT
    Fetch the full Markdown body of one of your saved summaries by its public token.
    Use this to build on a previous summary instead of re-reading the session materials.
    Only summaries created by the authenticated user can be retrieved.
  TEXT

  annotations(
    read_only_hint: true,
    destructive_hint: false,
    idempotent_hint: true,
    open_world_hint: false
  )

  input_schema(
    properties: {
      public_token: {
        type: "string",
        description: "The token from the summary's shareable URL (the part after /s/)"
      }
    },
    required: [ "public_token" ]
  )

  output_schema(
    type: "object",
    properties: {
      public_token: { type: "string" },
      url: { type: "string" },
      title: { type: "string" },
      body: { type: "string" },
      client_name: { type: "string" },
      session_id: { type: "integer" },
      meeting_number: { type: "string" },
      group: { type: "string" },
      created_at: { type: "string" }
    },
    required: [ "public_token", "url", "title", "body" ]
  )

  class << self
    def call(server_context:, **params)
      summary = server_context[:user].summaries
        .includes(:session)
        .find_by(public_token: params[:public_token])

      unless summary
        return error_response("summary_not_found", "Summary not found: #{params[:public_token]}")
      end

      data = {
        public_token: summary.public_token,
        url: summary.public_url,
        title: summary.title,
        body: summary.body,
        client_name: summary.client_name,
        session_id: summary.session&.datatracker_id,
        meeting_number: summary.meeting_number,
        group: summary.group_acronym,
        created_at: summary.created_at.iso8601
      }

      MCP::Tool::Response.new(
        [ { type: "text", text: JSON.generate(data) } ],
        structured_content: data
      )
    end

    private

    def error_response(code, message)
      MCP::Tool::Response.new(
        [ { type: "text", text: JSON.generate({ error: code, message: message }) } ],
        error: true
      )
    end
  end
end
