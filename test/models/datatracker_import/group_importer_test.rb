# frozen_string_literal: true

require "test_helper"

class DatatrackerImport::GroupImporterTest < ActiveSupport::TestCase
  setup do
    @mock_client = Minitest::Mock.new
    @mock_groups_resource = Minitest::Mock.new
    @mock_client.expect(:groups, @mock_groups_resource)
    @importer = DatatrackerImport::GroupImporter.new(client: @mock_client)
  end

  test "imports groups from API response" do
    api_objects = [
      {
        "acronym" => "httpbis",
        "name" => "HTTP",
        "type" => "wg",
        "state" => "active",
        "description" => "HTTP working group",
        "list_email" => "httpbis@ietf.org",
        "list_archive" => "https://mailarchive.ietf.org/arch/browse/httpbis/",
        "parent" => nil,
        "resource_uri" => "/api/v1/group/group/5000/"
      }
    ]

    mock_response = Minitest::Mock.new
    mock_response.expect(:objects, api_objects)
    mock_response.expect(:next_page?, false)
    @mock_groups_resource.expect(:list, mock_response) { true }

    assert_difference "Group.count", 1 do
      stats = @importer.import
      assert_equal 1, stats[:created]
      assert_equal 0, stats[:errors]
    end

    group = Group.find_by(acronym: "httpbis")
    assert_equal "HTTP", group.name
    assert_equal "wg", group.group_type
    assert_equal "active", group.state
  end

  test "extracts name from URI-style type and state fields" do
    api_objects = [
      {
        "acronym" => "uritest",
        "name" => "URI Test",
        "type" => "/api/v1/name/grouptypename/wg/",
        "state" => "/api/v1/name/groupstatename/active/",
        "description" => nil,
        "list_email" => nil,
        "list_archive" => nil,
        "parent" => nil,
        "resource_uri" => "/api/v1/group/group/5001/"
      }
    ]

    mock_response = Minitest::Mock.new
    mock_response.expect(:objects, api_objects)
    mock_response.expect(:next_page?, false)
    @mock_groups_resource.expect(:list, mock_response) { true }

    @importer.import

    group = Group.find_by(acronym: "uritest")
    assert_equal "wg", group.group_type
    assert_equal "active", group.state
  end

  test "resolves parent references in second pass" do
    parent_uri = groups(:art).resource_uri
    api_objects = [
      {
        "acronym" => "childwg",
        "name" => "Child WG",
        "type" => "wg",
        "state" => "active",
        "description" => nil,
        "list_email" => nil,
        "list_archive" => nil,
        "parent" => parent_uri,
        "resource_uri" => "/api/v1/group/group/5002/"
      }
    ]

    mock_response = Minitest::Mock.new
    mock_response.expect(:objects, api_objects)
    mock_response.expect(:next_page?, false)
    @mock_groups_resource.expect(:list, mock_response) { true }

    @importer.import

    group = Group.find_by(acronym: "childwg")
    assert_equal groups(:art), group.parent
  end
end
