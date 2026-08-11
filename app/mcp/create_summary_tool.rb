# frozen_string_literal: true

class CreateSummaryTool < MCP::Tool
  description <<~TEXT
    Save an AI-generated summary of an IETF meeting and return its shareable URL.
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
      meeting_number: {
        type: "string",
        description: "The meeting the summary is about (e.g. '124'), as returned by list_meetings_tool"
      },
      group_acronym: {
        type: "string",
        description: "The working group the summary is about (e.g. 'tls'). Omit for a summary that is not about one group."
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
    required: %w[meeting_number title body]
  )

  output_schema(
    type: "object",
    properties: {
      public_token: { type: "string" },
      url: { type: "string" },
      title: { type: "string" },
      meeting_number: { type: "string" },
      group: { type: "string" },
      created_at: { type: "string" }
    },
    required: [ "public_token", "url", "title" ]
  )

  class << self
    def call(server_context:, **params)
      meeting = Meeting.find_by(number: params[:meeting_number])
      unless meeting
        return error_response("meeting_not_found", "Meeting #{params[:meeting_number]} not found")
      end

      group = nil
      if params[:group_acronym].present?
        group = Group.find_by(acronym: params[:group_acronym])
        unless group
          return error_response("group_not_found", "Group #{params[:group_acronym]} not found")
        end
      end

      summary = build_summary(meeting, group, server_context, params)
      unless summary.save
        return error_response("validation_failed", summary.errors.full_messages.to_sentence)
      end

      data = {
        public_token: summary.public_token,
        url: summary.public_url,
        title: summary.title,
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

    def build_summary(meeting, group, server_context, params)
      application = server_context[:oauth_application]

      Summary.new(
        meeting: meeting,
        group: group,
        user: server_context[:user],
        oauth_application: application,
        client_name: application&.name.presence || Summary::UNKNOWN_CLIENT_NAME,
        meeting_number: meeting.number,
        group_acronym: group&.acronym,
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
