# frozen_string_literal: true

require "test_helper"

class FullImportJobTest < ActiveJob::TestCase
  test "calls FullImport with meeting number" do
    mock_importer = Minitest::Mock.new
    mock_importer.expect :import_meeting, {}, meeting_number: "124"

    DatatrackerImport::FullImport.stub(:new, mock_importer) do
      FullImportJob.perform_now("124")
    end

    assert_mock mock_importer
  end
end
