# frozen_string_literal: true

require "test_helper"

class Admin::StaleReportsControllerTest < ActionDispatch::IntegrationTest
  include AuthTestHelper

  setup do
    @report = StaleReport.create!(reportable: meetings(:ietf124), user: users(:bob), message: "Stale data")
  end

  test "unauthenticated user is redirected to login" do
    get admin_stale_reports_url
    assert_redirected_to login_path
  end

  test "non-admin user is redirected to root" do
    sign_in_as(users(:bob))
    get admin_stale_reports_url
    assert_redirected_to "/"
  end

  test "admin can view stale reports" do
    sign_in_as(users(:alice))
    get admin_stale_reports_url
    assert_response :success
  end

  test "admin can acknowledge a report" do
    sign_in_as(users(:alice))
    patch acknowledge_admin_stale_report_path(@report)
    assert_redirected_to admin_stale_reports_path
    assert @report.reload.acknowledged?
  end

  test "admin can resolve a report" do
    sign_in_as(users(:alice))
    @report.acknowledged!
    patch resolve_admin_stale_report_path(@report)
    assert_redirected_to admin_stale_reports_path
    assert @report.reload.resolved?
  end
end
