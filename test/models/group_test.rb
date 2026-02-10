# frozen_string_literal: true

require "test_helper"

class GroupTest < ActiveSupport::TestCase
  test "valid group" do
    group = Group.new(acronym: "httpbis", name: "HTTP", group_type: "wg", state: "active",
                      resource_uri: "/api/v1/group/group/1234/")
    assert group.valid?
  end

  test "requires acronym" do
    group = Group.new(resource_uri: "/api/v1/group/group/1111/")
    assert_not group.valid?
    assert_includes group.errors[:acronym], "can't be blank"
  end

  test "requires resource_uri" do
    group = Group.new(acronym: "test")
    assert_not group.valid?
    assert_includes group.errors[:resource_uri], "can't be blank"
  end

  test "acronym must be unique" do
    group = Group.new(acronym: groups(:tls).acronym, resource_uri: "/api/v1/group/group/9000/")
    assert_not group.valid?
    assert_includes group.errors[:acronym], "has already been taken"
  end

  test "resource_uri must be unique" do
    group = Group.new(acronym: "newwg", resource_uri: groups(:tls).resource_uri)
    assert_not group.valid?
    assert_includes group.errors[:resource_uri], "has already been taken"
  end

  test "parent association" do
    assert_equal groups(:art), groups(:tls).parent
    assert_includes groups(:art).children, groups(:tls)
  end

  test "has_many sessions" do
    assert_includes groups(:tls).sessions, sessions(:tls_at_124)
  end

  test "has_many documents" do
    assert_includes groups(:tls).documents, documents(:tls_chairs_slides)
  end

  test "nullifies children when destroyed" do
    groups(:art).destroy
    assert_nil groups(:tls).reload.parent_id
  end

  test "active scope" do
    active = Group.active
    assert_includes active, groups(:tls)
    assert_not_includes active, groups(:closed_wg)
  end

  test "working_groups scope" do
    wgs = Group.working_groups
    assert_includes wgs, groups(:tls)
    assert_not_includes wgs, groups(:art)
  end

  test "to_s returns acronym" do
    assert_equal "tls", groups(:tls).to_s
  end
end
