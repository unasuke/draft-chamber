# frozen_string_literal: true

class TrackDraftTool < MCP::Tool
  description "Start or stop tracking an internet-draft for new revision updates"

  annotations(
    read_only_hint: false,
    destructive_hint: false,
    idempotent_hint: true,
    open_world_hint: true
  )

  input_schema(
    properties: {
      draft_name: {
        type: "string",
        description: "The internet-draft name (e.g. 'draft-ietf-tls-esni')"
      },
      action: {
        type: "string",
        enum: %w[track untrack],
        description: "Whether to start or stop tracking the draft"
      }
    },
    required: %w[draft_name action]
  )

  class << self
    def call(server_context:, **params)
      case params[:action]
      when "track"
        track_draft(params[:draft_name])
      when "untrack"
        untrack_draft(params[:draft_name])
      end
    end

    private

    def track_draft(draft_name)
      tracked_draft = TrackedDraft.find_or_initialize_by(draft_name: draft_name)

      if tracked_draft.persisted? && tracked_draft.active?
        return success_response(tracked_draft, message: "Already tracking")
      end

      tracked_draft.status = "active"

      if tracked_draft.save
        CheckDraftUpdatesJob.perform_later(draft_name)
        success_response(tracked_draft, message: "Now tracking")
      else
        error_response(tracked_draft.errors.full_messages.to_sentence)
      end
    end

    def untrack_draft(draft_name)
      tracked_draft = TrackedDraft.find_by!(draft_name: draft_name)
      tracked_draft.archived!

      success_response(tracked_draft, message: "Stopped tracking")
    rescue ActiveRecord::RecordNotFound
      error_response("Not tracking: #{draft_name}")
    end

    def success_response(tracked_draft, message:)
      MCP::Tool::Response.new([ {
        type: "text",
        text: JSON.generate({
          message: message,
          draft_name: tracked_draft.draft_name,
          status: tracked_draft.status,
          last_known_rev: tracked_draft.last_known_rev,
          last_checked_at: tracked_draft.last_checked_at&.iso8601
        })
      } ])
    end

    def error_response(message)
      MCP::Tool::Response.new([ {
        type: "text",
        text: message
      } ], error: true)
    end
  end
end
