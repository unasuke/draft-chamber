# frozen_string_literal: true

require "test_helper"

class SessionTest < ActiveSupport::TestCase
  test "valid session" do
    session = Session.new(
      meeting: meetings(:ietf124),
      group: groups(:tls),
      resource_uri: "/api/v1/meeting/session/99999/"
    )
    assert session.valid?
  end

  test "requires meeting" do
    session = Session.new(resource_uri: "/api/v1/meeting/session/99998/")
    assert_not session.valid?
    assert_includes session.errors[:meeting], "must exist"
  end

  test "group is optional" do
    session = Session.new(
      meeting: meetings(:ietf124),
      group: nil,
      resource_uri: "/api/v1/meeting/session/99997/"
    )
    assert session.valid?
  end

  test "requires resource_uri" do
    session = Session.new(meeting: meetings(:ietf124))
    assert_not session.valid?
    assert_includes session.errors[:resource_uri], "can't be blank"
  end

  test "resource_uri must be unique" do
    session = Session.new(
      meeting: meetings(:ietf124),
      resource_uri: sessions(:tls_at_124).resource_uri
    )
    assert_not session.valid?
    assert_includes session.errors[:resource_uri], "has already been taken"
  end

  test "datatracker_id must be unique" do
    session = Session.new(
      meeting: meetings(:ietf124),
      datatracker_id: sessions(:tls_at_124).datatracker_id,
      resource_uri: "/api/v1/meeting/session/99996/"
    )
    assert_not session.valid?
    assert_includes session.errors[:datatracker_id], "has already been taken"
  end

  test "datatracker_id nil is allowed for multiple records" do
    s1 = Session.new(meeting: meetings(:ietf124), datatracker_id: nil,
                     resource_uri: "/api/v1/meeting/session/99995/")
    s1.save!
    s2 = Session.new(meeting: meetings(:ietf124), datatracker_id: nil,
                     resource_uri: "/api/v1/meeting/session/99994/")
    assert s2.valid?
  end

  test "belongs_to meeting" do
    assert_equal meetings(:ietf124), sessions(:tls_at_124).meeting
  end

  test "belongs_to group" do
    assert_equal groups(:tls), sessions(:tls_at_124).group
  end

  test "has_many session_presentations" do
    assert_includes sessions(:tls_at_124).session_presentations,
                    session_presentations(:tls_chairs_at_124)
  end

  test "has_many documents through session_presentations" do
    assert_includes sessions(:tls_at_124).documents, documents(:tls_chairs_slides)
  end
end
