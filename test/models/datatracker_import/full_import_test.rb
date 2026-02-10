# frozen_string_literal: true

require "test_helper"

class DatatrackerImport::FullImportTest < ActiveSupport::TestCase
  test "import_meeting calls importers in correct order" do
    call_order = []

    mock_group_importer = Object.new
    mock_group_importer.define_singleton_method(:import) do |_params = {}|
      call_order << :groups
      { created: 1, updated: 0, errors: 0 }
    end

    mock_meeting_importer = Object.new
    mock_meeting_importer.define_singleton_method(:import) do |_params = {}|
      call_order << :meetings
      { created: 1, updated: 0, errors: 0 }
    end

    mock_session_importer = Object.new
    mock_session_importer.define_singleton_method(:import) do |meeting_number:|
      call_order << :sessions
      { created: 5, updated: 0, errors: 0 }
    end

    mock_sp_importer = Object.new
    mock_sp_importer.define_singleton_method(:import) do |meeting_number:, group_acronym: nil|
      call_order << :session_presentations
      { created: 10, updated: 0, errors: 0 }
    end

    DatatrackerImport::GroupImporter.stub(:new, mock_group_importer) do
      DatatrackerImport::MeetingImporter.stub(:new, mock_meeting_importer) do
        DatatrackerImport::SessionImporter.stub(:new, mock_session_importer) do
          DatatrackerImport::SessionPresentationImporter.stub(:new, mock_sp_importer) do
            full_import = DatatrackerImport::FullImport.new
            results = full_import.import_meeting(meeting_number: "124")

            assert_equal [ :groups, :meetings, :sessions, :session_presentations ], call_order
            assert_equal 4, results.size
            assert_equal({ created: 1, updated: 0, errors: 0 }, results[:groups])
            assert_equal({ created: 10, updated: 0, errors: 0 }, results[:session_presentations])
          end
        end
      end
    end
  end
end
