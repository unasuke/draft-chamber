# frozen_string_literal: true

require "test_helper"

class ImportMeetingJobTest < ActiveJob::TestCase
  test "calls MeetingImporter with meeting number" do
    mock_importer = Minitest::Mock.new
    mock_importer.expect :import, { created: 1, updated: 0, errors: 0 }, number: "124"

    DatatrackerImport::MeetingImporter.stub(:new, mock_importer) do
      ImportMeetingJob.perform_now("124")
    end

    assert_mock mock_importer
  end
end
