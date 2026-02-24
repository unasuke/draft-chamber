# frozen_string_literal: true

require "test_helper"

class ImportGroupsJobTest < ActiveJob::TestCase
  test "calls GroupImporter with params" do
    mock_importer = Minitest::Mock.new
    mock_importer.expect :import, { created: 5, updated: 2, errors: 0 }, [ { state: "active" } ]

    DatatrackerImport::GroupImporter.stub(:new, mock_importer) do
      ImportGroupsJob.perform_now(state: "active")
    end

    assert_mock mock_importer
  end

  test "passes type when provided" do
    mock_importer = Minitest::Mock.new
    mock_importer.expect :import, { created: 1, updated: 0, errors: 0 }, [ { state: "active", type: "wg" } ]

    DatatrackerImport::GroupImporter.stub(:new, mock_importer) do
      ImportGroupsJob.perform_now(state: "active", type: "wg")
    end

    assert_mock mock_importer
  end

  test "omits type when nil" do
    mock_importer = Minitest::Mock.new
    mock_importer.expect :import, { created: 0, updated: 0, errors: 0 }, [ { state: "active" } ]

    DatatrackerImport::GroupImporter.stub(:new, mock_importer) do
      ImportGroupsJob.perform_now(state: "active", type: nil)
    end

    assert_mock mock_importer
  end
end
