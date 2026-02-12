# frozen_string_literal: true

require "test_helper"

class SyncMeetingDataJobTest < ActiveSupport::TestCase
  test "calls session and session presentation importers in order" do
    call_order = []

    mock_session_importer = Object.new
    mock_session_importer.define_singleton_method(:import) do |meeting_number:|
      call_order << :sessions
      { created: 2, updated: 3, errors: 0 }
    end

    mock_sp_importer = Object.new
    mock_sp_importer.define_singleton_method(:import) do |meeting_number:, group_acronym: nil|
      call_order << :session_presentations
      { created: 5, updated: 1, errors: 0 }
    end

    DatatrackerImport::SessionImporter.stub(:new, mock_session_importer) do
      DatatrackerImport::SessionPresentationImporter.stub(:new, mock_sp_importer) do
        SyncMeetingDataJob.perform_now("124")
      end
    end

    assert_equal [ :sessions, :session_presentations ], call_order
  end
end
