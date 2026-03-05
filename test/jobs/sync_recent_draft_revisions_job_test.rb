# frozen_string_literal: true

require "test_helper"

class SyncRecentDraftRevisionsJobTest < ActiveSupport::TestCase
  test "creates TrackedDraft for new documents from feed" do
    events = [
      { "doc" => "/api/v1/doc/document/draft-ietf-new-protocol/", "rev" => "00", "id" => 200 }
    ]

    mock_response = Minitest::Mock.new
    mock_response.expect(:objects, events)

    mock_resource = Minitest::Mock.new
    mock_resource.expect(:list, mock_response, order_by: "-id", limit: 20)

    mock_client = Minitest::Mock.new
    mock_client.expect(:new_revision_doc_events, mock_resource)

    mock_importer = Object.new
    mock_importer.define_singleton_method(:import) { |**_| { created: 0, updated: 0, errors: 0 } }

    Datatracker::Client.stub(:new, mock_client) do
      DatatrackerImport::DocumentImporter.stub(:new, mock_importer) do
        SyncRecentDraftRevisionsJob.perform_now
      end
    end

    tracked = TrackedDraft.find_by(draft_name: "draft-ietf-new-protocol")
    assert tracked
    assert_equal "active", tracked.status
    assert_equal "00", tracked.last_known_rev
    assert_not_nil tracked.last_checked_at
  end

  test "updates existing TrackedDraft rev from feed" do
    tracked_draft = tracked_drafts(:tls_esni)
    events = [
      { "doc" => "/api/v1/doc/document/draft-ietf-tls-esni/", "rev" => "25", "id" => 300 }
    ]

    mock_response = Minitest::Mock.new
    mock_response.expect(:objects, events)

    mock_resource = Minitest::Mock.new
    mock_resource.expect(:list, mock_response, order_by: "-id", limit: 20)

    mock_client = Minitest::Mock.new
    mock_client.expect(:new_revision_doc_events, mock_resource)

    Datatracker::Client.stub(:new, mock_client) do
      SyncRecentDraftRevisionsJob.perform_now
    end

    tracked_draft.reload
    assert_equal "25", tracked_draft.last_known_rev
  end
end
