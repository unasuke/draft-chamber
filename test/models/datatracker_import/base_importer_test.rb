# frozen_string_literal: true

require "test_helper"

class DatatrackerImport::BaseImporterTest < ActiveSupport::TestCase
  setup do
    @importer = DatatrackerImport::BaseImporter.new
  end

  test "initializes with default stats" do
    assert_equal({ created: 0, updated: 0, errors: 0 }, @importer.stats)
  end

  test "import raises NotImplementedError" do
    assert_raises NotImplementedError do
      @importer.import
    end
  end

  test "extract_name_from_uri extracts last segment from API URI" do
    result = @importer.send(:extract_name_from_uri, "/api/v1/name/groupstatename/active/")
    assert_equal "active", result
  end

  test "extract_name_from_uri returns plain strings as-is" do
    assert_equal "active", @importer.send(:extract_name_from_uri, "active")
  end

  test "extract_name_from_uri returns nil for nil" do
    assert_nil @importer.send(:extract_name_from_uri, nil)
  end

  test "extract_name_from_uri handles non-API strings" do
    assert_equal "wg", @importer.send(:extract_name_from_uri, "wg")
  end

  test "upsert_record creates new record" do
    assert_difference "Group.count", 1 do
      @importer.send(:upsert_record, Group,
        resource_uri: "/api/v1/group/group/new/",
        attributes: { acronym: "newwg", name: "New WG" })
    end
    assert_equal 1, @importer.stats[:created]
    assert_equal 0, @importer.stats[:updated]
  end

  test "upsert_record updates existing record" do
    assert_no_difference "Group.count" do
      @importer.send(:upsert_record, Group,
        resource_uri: groups(:tls).resource_uri,
        attributes: { acronym: "tls", name: "Updated Name" })
    end
    assert_equal 0, @importer.stats[:created]
    assert_equal 1, @importer.stats[:updated]
    assert_equal "Updated Name", groups(:tls).reload.name
  end

  test "upsert_record increments errors on validation failure" do
    result = @importer.send(:upsert_record, Group,
      resource_uri: "/api/v1/group/group/invalid/",
      attributes: { acronym: nil })
    assert_nil result
    assert_equal 1, @importer.stats[:errors]
  end
end
