# frozen_string_literal: true

require "test_helper"

class ImportSessionsJobTest < ActiveJob::TestCase
  test "calls SessionImporter with meeting number" do
    mock_importer = Minitest::Mock.new
    mock_importer.expect :import, { created: 3, updated: 0, errors: 0 }, meeting_number: "124"

    DatatrackerImport::SessionImporter.stub(:new, mock_importer) do
      ImportSessionsJob.perform_now("124")
    end

    assert_mock mock_importer
  end
end
