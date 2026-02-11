# frozen_string_literal: true

require "test_helper"

class MissionControlJobsTest < ActionDispatch::IntegrationTest
  include AuthTestHelper

  test "unauthenticated user is redirected to login" do
    get "/admin/jobs"
    assert_redirected_to "/login"
  end

  test "non-admin user is redirected to root with alert" do
    sign_in_as(users(:bob))
    get "/admin/jobs"
    assert_redirected_to "/"
    assert_equal "You are not authorized to access this page", flash[:alert]
  end

  test "admin user can access the jobs dashboard" do
    sign_in_as(users(:alice))
    get "/admin/jobs"
    assert_response :success
  end
end
