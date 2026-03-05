# frozen_string_literal: true

require "test_helper"

class TrackedDraftTest < ActiveSupport::TestCase
  test "valid tracked draft" do
    tracked_draft = TrackedDraft.new(draft_name: "draft-ietf-httpbis-http2bis")
    assert tracked_draft.valid?
  end

  test "requires draft_name" do
    tracked_draft = TrackedDraft.new
    assert_not tracked_draft.valid?
    assert tracked_draft.errors[:draft_name].any?
  end

  test "draft_name must be unique" do
    duplicate = TrackedDraft.new(draft_name: tracked_drafts(:tls_esni).draft_name)
    assert_not duplicate.valid?
  end

  test "default status is active" do
    tracked_draft = TrackedDraft.new(draft_name: "draft-ietf-httpbis-http2bis")
    assert_equal "active", tracked_draft.status
  end

  test "can associate with document" do
    tracked_draft = tracked_drafts(:tls_esni)
    assert_equal documents(:tls_draft), tracked_draft.document
  end

  test "document association is optional" do
    tracked_draft = TrackedDraft.new(draft_name: "draft-ietf-httpbis-http2bis")
    assert tracked_draft.valid?
    assert_nil tracked_draft.document
  end

  test "status transitions" do
    tracked_draft = tracked_drafts(:tls_esni)
    assert tracked_draft.active?
    tracked_draft.archived!
    assert tracked_draft.archived?
  end
end
