# frozen_string_literal: true

require "test_helper"

class MeetingTest < ActiveSupport::TestCase
  test "valid meeting" do
    meeting = Meeting.new(number: "125", meeting_type: "ietf", date: "2026-03-01",
                          resource_uri: "/api/v1/meeting/meeting/125/")
    assert meeting.valid?
  end

  test "requires number" do
    meeting = Meeting.new(resource_uri: "/api/v1/meeting/meeting/999/")
    assert_not meeting.valid?
    assert_includes meeting.errors[:number], "can't be blank"
  end

  test "requires resource_uri" do
    meeting = Meeting.new(number: "999")
    assert_not meeting.valid?
    assert_includes meeting.errors[:resource_uri], "can't be blank"
  end

  test "number must be unique" do
    meeting = Meeting.new(number: "124", resource_uri: "/api/v1/meeting/meeting/124dup/")
    assert_not meeting.valid?
    assert_includes meeting.errors[:number], "has already been taken"
  end

  test "has_many sessions" do
    assert_includes meetings(:ietf124).sessions, sessions(:tls_at_124)
  end

  test "ietf scope" do
    ietf = Meeting.ietf
    assert_includes ietf, meetings(:ietf124)
    assert_not_includes ietf, meetings(:interim_tls)
  end

  test "interim scope" do
    interim = Meeting.interim
    assert_includes interim, meetings(:interim_tls)
    assert_not_includes interim, meetings(:ietf124)
  end

  test "recent scope orders by date descending" do
    recent = Meeting.recent
    assert_equal meetings(:ietf124), recent.first
  end

  test "to_s returns number" do
    assert_equal "124", meetings(:ietf124).to_s
  end

  test "syncable includes meetings that ended recently" do
    travel_to Date.new(2025, 11, 20) do
      assert_includes Meeting.syncable, meetings(:ietf124)
    end
  end

  test "syncable includes future meetings" do
    travel_to Date.new(2025, 10, 1) do
      assert_includes Meeting.syncable, meetings(:ietf124)
    end
  end

  test "syncable excludes meetings that ended more than 30 days ago" do
    travel_to Date.new(2026, 1, 1) do
      assert_not_includes Meeting.syncable, meetings(:ietf124)
    end
  end
end
