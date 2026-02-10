# frozen_string_literal: true

require "test_helper"

class DatatrackerImport::SessionImporterTest < ActiveSupport::TestCase
  setup do
    @mock_client = Minitest::Mock.new
    @mock_sessions_resource = Minitest::Mock.new
    @mock_client.expect(:sessions, @mock_sessions_resource)
    @importer = DatatrackerImport::SessionImporter.new(client: @mock_client)
  end

  test "imports sessions for a meeting" do
    api_objects = [
      {
        "id" => 50000,
        "meeting" => meetings(:ietf124).resource_uri,
        "group" => groups(:tls).resource_uri,
        "name" => "tls-new",
        "purpose" => "regular",
        "requested_duration" => "1:30:00",
        "on_agenda" => true,
        "remote_instructions" => "https://meetecho.ietf.org/tls",
        "attendees" => 100,
        "resource_uri" => "/api/v1/meeting/session/50000/"
      }
    ]

    mock_response = Minitest::Mock.new
    mock_response.expect(:objects, api_objects)
    mock_response.expect(:next_page?, false)
    @mock_sessions_resource.expect(:list, mock_response) { true }

    assert_difference "Session.count", 1 do
      stats = @importer.import(meeting_number: "124")
      assert_equal 1, stats[:created]
    end

    session = Session.find_by(datatracker_id: 50000)
    assert_equal meetings(:ietf124), session.meeting
    assert_equal groups(:tls), session.group
    assert_equal "tls-new", session.name
  end

  test "skips session when meeting is not found" do
    api_objects = [
      {
        "id" => 50001,
        "meeting" => "/api/v1/meeting/meeting/999/",
        "group" => groups(:tls).resource_uri,
        "name" => "orphan",
        "purpose" => "regular",
        "requested_duration" => "1:00:00",
        "on_agenda" => true,
        "remote_instructions" => nil,
        "attendees" => nil,
        "resource_uri" => "/api/v1/meeting/session/50001/"
      }
    ]

    mock_response = Minitest::Mock.new
    mock_response.expect(:objects, api_objects)
    mock_response.expect(:next_page?, false)
    @mock_sessions_resource.expect(:list, mock_response) { true }

    assert_no_difference "Session.count" do
      stats = @importer.import(meeting_number: "999")
      assert_equal 1, stats[:errors]
    end
  end

  test "allows nil group" do
    api_objects = [
      {
        "id" => 50002,
        "meeting" => meetings(:ietf124).resource_uri,
        "group" => nil,
        "name" => "plenary",
        "purpose" => "plenary",
        "requested_duration" => "2:00:00",
        "on_agenda" => true,
        "remote_instructions" => nil,
        "attendees" => nil,
        "resource_uri" => "/api/v1/meeting/session/50002/"
      }
    ]

    mock_response = Minitest::Mock.new
    mock_response.expect(:objects, api_objects)
    mock_response.expect(:next_page?, false)
    @mock_sessions_resource.expect(:list, mock_response) { true }

    assert_difference "Session.count", 1 do
      @importer.import(meeting_number: "124")
    end

    session = Session.find_by(datatracker_id: 50002)
    assert_nil session.group
  end
end
