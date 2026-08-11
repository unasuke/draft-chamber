# frozen_string_literal: true

class ListSummariesTool < MCP::Tool
  DEFAULT_LIMIT = 20
  MAX_LIMIT = 100

  description <<~TEXT
    List summaries you have previously saved. Use this to find an earlier summary before writing
    a new one, or to give the user the shareable URL of something they saved before.
    Only returns summaries created by the authenticated user.
  TEXT

  annotations(
    read_only_hint: true,
    destructive_hint: false,
    idempotent_hint: true,
    open_world_hint: false
  )

  input_schema(
    properties: {
      meeting_number: {
        type: "string",
        description: "Only return summaries for this meeting (e.g. '124')"
      },
      group_acronym: {
        type: "string",
        description: "Only return summaries for this working group (e.g. 'tls')"
      },
      limit: {
        type: "integer",
        description: "How many summaries to return (default #{DEFAULT_LIMIT}, maximum #{MAX_LIMIT})"
      },
      offset: {
        type: "integer",
        description: "How many summaries to skip, for paging through the results (default 0)"
      }
    }
  )

  output_schema(
    type: "object",
    properties: {
      summaries: {
        type: "array",
        items: {
          type: "object",
          properties: {
            public_token: { type: "string" },
            url: { type: "string" },
            title: { type: "string" },
            client_name: { type: "string" },
            meeting_number: { type: "string" },
            group: { type: "string" },
            created_at: { type: "string" }
          },
          required: [ "public_token", "url", "title" ]
        }
      },
      total: { type: "integer" }
    },
    required: [ "summaries", "total" ]
  )

  class << self
    def call(server_context:, **params)
      scope = filtered_scope(server_context[:user], params)
      total = scope.count

      summaries = scope.recent
        .includes(:meeting, :group)
        .limit(clamped_limit(params[:limit]))
        .offset(clamped_offset(params[:offset]))

      data = { summaries: summaries.map { |summary| summary_to_hash(summary) }, total: total }

      MCP::Tool::Response.new(
        [ { type: "text", text: JSON.generate(data) } ],
        structured_content: data
      )
    end

    private

    def filtered_scope(user, params)
      scope = user.summaries.linked
      scope = scope.where(meeting_number: params[:meeting_number]) if params[:meeting_number]
      scope = scope.where(group_acronym: params[:group_acronym]) if params[:group_acronym]
      scope
    end

    def clamped_limit(limit)
      return DEFAULT_LIMIT if limit.nil?

      limit.clamp(1, MAX_LIMIT)
    end

    def clamped_offset(offset)
      return 0 if offset.nil?

      [ offset, 0 ].max
    end

    def summary_to_hash(summary)
      {
        public_token: summary.public_token,
        url: summary.public_url,
        title: summary.title,
        client_name: summary.client_name,
        meeting_number: summary.meeting_number,
        group: summary.group_acronym,
        created_at: summary.created_at.iso8601
      }
    end
  end
end
