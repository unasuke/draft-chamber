# frozen_string_literal: true

class CreateSummaryTool < MCP::Tool
  description <<~TEXT
    Save an AI-generated summary of an IETF session and return its shareable URL.
    Call this after reading session materials when the user wants to keep or share the summary.
    Each call creates a new summary; there is no update, so to correct one create a new summary
    and delete the old one from the web UI.
  TEXT

  annotations(
    read_only_hint: false,
    destructive_hint: false,
    idempotent_hint: false,
    open_world_hint: false
  )

  input_schema(
    properties: {
      session_id: {
        type: "integer",
        description: "Datatracker session ID, as returned by list_sessions_tool"
      },
      title: {
        type: "string",
        description: "Short headline for the summary (255 characters or less)"
      },
      body: {
        type: "string",
        description: "The summary itself, written in Markdown (GFM tables and strikethrough are supported)"
      }
    },
    required: %w[session_id title body]
  )

  output_schema(
    type: "object",
    properties: {
      public_token: { type: "string" },
      url: { type: "string" },
      title: { type: "string" },
      session_id: { type: "integer" },
      meeting_number: { type: "string" },
      group: { type: "string" },
      created_at: { type: "string" }
    },
    required: [ "public_token", "url", "title" ]
  )

  class << self
    def call(server_context:, **params)
      session = Session.includes(:meeting, :group).find_by(datatracker_id: params[:session_id])
      unless session
        return error_response("session_not_found", "Session with ID #{params[:session_id]} not found")
      end

      summary = build_summary(session, server_context, params)
      unless summary.save
        return error_response("validation_failed", summary.errors.full_messages.to_sentence)
      end

      data = {
        public_token: summary.public_token,
        url: summary.public_url,
        title: summary.title,
        session_id: session.datatracker_id,
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

    def build_summary(session, server_context, params)
      application = server_context[:oauth_application]

      Summary.new(
        session: session,
        user: server_context[:user],
        oauth_application: application,
        client_name: application&.name.presence || Summary::UNKNOWN_CLIENT_NAME,
        meeting_number: session.meeting.number,
        group_acronym: session.group&.acronym,
        title: params[:title],
        body: params[:body]
      )
    end

    def error_response(code, message)
      MCP::Tool::Response.new(
        [ { type: "text", text: JSON.generate({ error: code, message: message }) } ],
        error: true
      )
    end
  end
end
