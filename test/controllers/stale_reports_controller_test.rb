# frozen_string_literal: true

require "test_helper"

class StaleReportsControllerTest < ActionDispatch::IntegrationTest
  include AuthTestHelper

  setup do
    sign_in_as(users(:bob))
  end

  test "can report a meeting as stale" do
    assert_difference "StaleReport.count", 1 do
      post meeting_stale_report_path(meetings(:ietf124)),
        headers: { "HTTP_REFERER" => meeting_url(meetings(:ietf124)) },
        params: { stale_report: { message: "Outdated info" } }
    end
    assert_redirected_to meeting_url(meetings(:ietf124))
    assert_equal "Thank you for reporting stale data.", flash[:notice]
  end

  test "can report a document as stale" do
    assert_difference "StaleReport.count", 1 do
      post document_stale_report_path(documents(:tls_chairs_slides)),
        headers: { "HTTP_REFERER" => document_url(documents(:tls_chairs_slides)) },
        params: { stale_report: { message: "" } }
    end
    assert_redirected_to document_url(documents(:tls_chairs_slides))
  end

  test "can report a meeting group page as stale" do
    assert_difference "StaleReport.count", 1 do
      post meeting_group_stale_report_path(meetings(:ietf124), groups(:tls))
    end
    assert_equal "Thank you for reporting stale data.", flash[:notice]
  end

  test "duplicate report shows error" do
    StaleReport.create!(reportable: meetings(:ietf124), user: users(:bob))
    assert_no_difference "StaleReport.count" do
      post meeting_stale_report_path(meetings(:ietf124))
    end
    assert flash[:alert].present?
  end

  test "unauthenticated user is redirected to login" do
    delete logout_path
    post meeting_stale_report_path(meetings(:ietf124))
    assert_redirected_to login_path
  end
end
