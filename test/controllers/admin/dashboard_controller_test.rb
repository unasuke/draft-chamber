# frozen_string_literal: true

require "test_helper"

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  include AuthTestHelper

  test "unauthenticated user is redirected to login" do
    get admin_root_url
    assert_redirected_to login_path
  end

  test "non-admin user is redirected to root with alert" do
    sign_in_as(users(:bob))
    get admin_root_url
    assert_redirected_to "/"
    assert_equal "You are not authorized to access this page", flash[:alert]
  end

  test "admin user can access the dashboard" do
    sign_in_as(users(:alice))
    get admin_root_url
    assert_response :success
  end

  test "dashboard shows statistics" do
    sign_in_as(users(:alice))
    get admin_root_url
    assert_select "p", text: "Meetings"
    assert_select "p", text: "Documents"
    assert_select "p", text: "Users"
  end

  test "dashboard shows download status table" do
    sign_in_as(users(:alice))
    get admin_root_url
    assert_select "th", text: "Download Status"
  end

  test "dashboard shows processing status table" do
    sign_in_as(users(:alice))
    get admin_root_url
    assert_select "th", text: "Processing Status"
  end

  test "navigation shows admin link for admin users" do
    sign_in_as(users(:alice))
    get meetings_url
    assert_select "a[href=?]", admin_root_path
  end

  test "navigation hides admin link for non-admin users" do
    sign_in_as(users(:bob))
    get meetings_url
    assert_select "a[href=?]", admin_root_path, count: 0
  end
end
