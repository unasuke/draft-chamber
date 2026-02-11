# frozen_string_literal: true

require "test_helper"

class MeetingsControllerTest < ActionDispatch::IntegrationTest
  include AuthTestHelper

  setup do
    sign_in_as(users(:alice))
  end

  test "should get index" do
    get meetings_url
    assert_response :success
  end

  test "should get show" do
    get meeting_url(meetings(:ietf124))
    assert_response :success
  end

  test "show page should list groups with sessions" do
    get meeting_url(meetings(:ietf124))
    assert_select "a[href=?]", meeting_group_path(meetings(:ietf124), groups(:tls))
    assert_select "a[href=?]", meeting_group_path(meetings(:ietf124), groups(:quic))
  end

  test "show page should not list groups without sessions" do
    get meeting_url(meetings(:ietf124))
    assert_select "td", text: "closedwg", count: 0
  end
end
