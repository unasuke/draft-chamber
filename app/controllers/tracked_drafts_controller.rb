# frozen_string_literal: true

class TrackedDraftsController < ApplicationController
  def index
    @tracked_drafts = TrackedDraft.active.includes(:document).order(updated_at: :desc)
  end

  def create
    @tracked_draft = TrackedDraft.find_or_initialize_by(draft_name: params[:draft_name])
    @tracked_draft.status = "active"

    if @tracked_draft.save
      CheckDraftUpdatesJob.perform_later(@tracked_draft.draft_name)
      redirect_to tracked_drafts_path, notice: "Now tracking #{@tracked_draft.draft_name}"
    else
      @tracked_drafts = TrackedDraft.active.includes(:document).order(updated_at: :desc)
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    @tracked_draft = TrackedDraft.find(params[:id])
    @tracked_draft.archived!
    redirect_to tracked_drafts_path, notice: "Stopped tracking #{@tracked_draft.draft_name}"
  end
end
