# frozen_string_literal: true

require "test_helper"

class ImportPresentationsJobTest < ActiveJob::TestCase
  test "calls SessionPresentationImporter with meeting number" do
    mock_importer = Minitest::Mock.new
    mock_importer.expect :import, { created: 10, updated: 0, errors: 0 },
      meeting_number: "124", group_acronym: nil

    DatatrackerImport::SessionPresentationImporter.stub(:new, mock_importer) do
      ImportPresentationsJob.perform_now("124")
    end

    assert_mock mock_importer
  end

  test "passes group_acronym when provided" do
    mock_importer = Minitest::Mock.new
    mock_importer.expect :import, { created: 2, updated: 0, errors: 0 },
      meeting_number: "124", group_acronym: "tls"

    DatatrackerImport::SessionPresentationImporter.stub(:new, mock_importer) do
      ImportPresentationsJob.perform_now("124", group_acronym: "tls")
    end

    assert_mock mock_importer
  end
end
