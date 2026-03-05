# frozen_string_literal: true

class ListTrackedDraftsTool < MCP::Tool
  description "List all tracked internet-drafts with their current revision status"

  annotations(
    read_only_hint: true,
    destructive_hint: false,
    idempotent_hint: true,
    open_world_hint: false
  )

  input_schema(
    properties: {
      include_archived: {
        type: "boolean",
        description: "Include archived (untracked) drafts in the list"
      }
    }
  )

  class << self
    def call(server_context:, **params)
      tracked_drafts = if params[:include_archived]
        TrackedDraft.includes(:document).order(updated_at: :desc)
      else
        TrackedDraft.active.includes(:document).order(updated_at: :desc)
      end

      results = tracked_drafts.map { |td| format_tracked_draft(td) }

      MCP::Tool::Response.new([ {
        type: "text",
        text: JSON.generate(results)
      } ])
    end

    private

    def format_tracked_draft(tracked_draft)
      result = {
        draft_name: tracked_draft.draft_name,
        status: tracked_draft.status,
        last_known_rev: tracked_draft.last_known_rev,
        last_checked_at: tracked_draft.last_checked_at&.iso8601
      }

      if tracked_draft.document
        result[:title] = tracked_draft.document.title
        result[:group] = tracked_draft.document.group&.acronym
      end

      result
    end
  end
end
