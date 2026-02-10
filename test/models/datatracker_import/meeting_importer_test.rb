# frozen_string_literal: true

require "test_helper"

class DatatrackerImport::MeetingImporterTest < ActiveSupport::TestCase
  setup do
    @mock_client = Minitest::Mock.new
    @mock_meetings_resource = Minitest::Mock.new
    @mock_client.expect(:meetings, @mock_meetings_resource)
    @importer = DatatrackerImport::MeetingImporter.new(client: @mock_client)
  end

  test "imports meetings from API response" do
    api_objects = [
      {
        "number" => "125",
        "type" => "ietf",
        "date" => "2026-03-14",
        "days" => 7,
        "city" => "Tokyo",
        "country" => "JP",
        "time_zone" => "Asia/Tokyo",
        "venue_name" => "Tokyo Big Sight",
        "attendees" => 1500,
        "resource_uri" => "/api/v1/meeting/meeting/125/"
      }
    ]

    mock_response = Minitest::Mock.new
    mock_response.expect(:objects, api_objects)
    mock_response.expect(:next_page?, false)
    @mock_meetings_resource.expect(:list, mock_response) { true }

    assert_difference "Meeting.count", 1 do
      stats = @importer.import(number: "125")
      assert_equal 1, stats[:created]
    end

    meeting = Meeting.find_by(number: "125")
    assert_equal "ietf", meeting.meeting_type
    assert_equal "Tokyo", meeting.city
    assert_equal "JP", meeting.country
  end

  test "updates existing meeting" do
    api_objects = [
      {
        "number" => "124",
        "type" => "ietf",
        "date" => "2025-11-01",
        "days" => 7,
        "city" => "Montreal",
        "country" => "CA",
        "time_zone" => "America/Montreal",
        "venue_name" => "Updated Venue",
        "attendees" => 1300,
        "resource_uri" => meetings(:ietf124).resource_uri
      }
    ]

    mock_response = Minitest::Mock.new
    mock_response.expect(:objects, api_objects)
    mock_response.expect(:next_page?, false)
    @mock_meetings_resource.expect(:list, mock_response) { true }

    assert_no_difference "Meeting.count" do
      stats = @importer.import
      assert_equal 1, stats[:updated]
    end

    assert_equal "Updated Venue", meetings(:ietf124).reload.venue_name
  end
end
