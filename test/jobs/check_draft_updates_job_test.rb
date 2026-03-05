# frozen_string_literal: true

require "test_helper"

class CheckDraftUpdatesJobTest < ActiveSupport::TestCase
  setup do
    @tracked_draft = tracked_drafts(:tls_esni)
  end

  test "updates last_checked_at when no events found" do
    mock_resource = Minitest::Mock.new
    mock_response = Minitest::Mock.new
    mock_response.expect(:objects, [])
    mock_resource.expect(:for_document, mock_response, [ "draft-ietf-tls-esni" ], limit: 1, order_by: "-id")

    mock_client = Minitest::Mock.new
    mock_client.expect(:new_revision_doc_events, mock_resource)

    Datatracker::Client.stub(:new, mock_client) do
      CheckDraftUpdatesJob.perform_now("draft-ietf-tls-esni")
    end

    @tracked_draft.reload
    assert_not_nil @tracked_draft.last_checked_at
    assert_equal "22", @tracked_draft.last_known_rev
  end

  test "updates last_known_rev when new revision found" do
    event = { "rev" => "23", "id" => 100 }
    mock_resource = Minitest::Mock.new
    mock_response = Minitest::Mock.new
    mock_response.expect(:objects, [ event ])
    mock_resource.expect(:for_document, mock_response, [ "draft-ietf-tls-esni" ], limit: 1, order_by: "-id")

    mock_client = Minitest::Mock.new
    mock_client.expect(:new_revision_doc_events, mock_resource)

    Datatracker::Client.stub(:new, mock_client) do
      CheckDraftUpdatesJob.perform_now("draft-ietf-tls-esni")
    end

    @tracked_draft.reload
    assert_equal "23", @tracked_draft.last_known_rev
    assert_not_nil @tracked_draft.last_checked_at
  end

  test "handles Datatracker::NotFoundError gracefully" do
    mock_resource = Object.new
    mock_resource.define_singleton_method(:for_document) do |*_args, **_kwargs|
      raise Datatracker::NotFoundError.new(response: Struct.new(:status, :body).new(404, ""))
    end

    mock_client = Minitest::Mock.new
    mock_client.expect(:new_revision_doc_events, mock_resource)

    Datatracker::Client.stub(:new, mock_client) do
      assert_nothing_raised do
        CheckDraftUpdatesJob.perform_now("draft-ietf-tls-esni")
      end
    end

    @tracked_draft.reload
    assert_not_nil @tracked_draft.last_checked_at
  end
end
