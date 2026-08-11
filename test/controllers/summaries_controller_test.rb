# frozen_string_literal: true

require "test_helper"

class SummariesControllerTest < ActionDispatch::IntegrationTest
  include AuthTestHelper

  test "index redirects to login when signed out" do
    get summaries_url

    assert_redirected_to login_path
  end

  test "index lists only summaries created by the signed in user" do
    sign_in_as(users(:alice))

    get summaries_url

    assert_response :success
    assert_select "td", text: /TLS WG at IETF 124/
    assert_select "td", text: /Bob's take on TLS WG/, count: 0
  end

  test "index excludes orphaned summaries" do
    sign_in_as(users(:alice))

    get summaries_url

    assert_response :success
    assert_select "td", text: /Summary of a deleted meeting/, count: 0
  end

  test "index links each summary to its shareable url" do
    sign_in_as(users(:alice))

    get summaries_url

    assert_select "a[href=?]", public_summary_path(summaries(:tls_124_by_alice).public_token)
  end

  test "index shows guidance when the user has no summaries" do
    users(:alice).summaries.destroy_all
    sign_in_as(users(:alice))

    get summaries_url

    assert_response :success
    assert_select "p", text: /No summaries yet/
  end

  test "destroy removes the summary owned by the signed in user" do
    sign_in_as(users(:bob))
    summary = summaries(:tls_124_by_bob)

    assert_difference "Summary.count", -1 do
      delete summary_url(summary)
    end

    assert_redirected_to summaries_path
    assert_equal "Summary deleted.", flash[:notice]
  end

  test "destroy returns 404 for another user's summary" do
    sign_in_as(users(:bob))
    summary = summaries(:tls_124_by_alice)

    assert_no_difference "Summary.count" do
      delete summary_url(summary)
    end

    assert_response :not_found
  end

  test "destroy allows an admin to delete another user's summary" do
    sign_in_as(users(:alice))
    summary = summaries(:tls_124_by_bob)

    assert_predicate users(:alice), :admin?
    assert_difference "Summary.count", -1 do
      delete summary_url(summary)
    end

    assert_redirected_to summaries_path
  end

  test "destroy redirects to login when signed out" do
    assert_no_difference "Summary.count" do
      delete summary_url(summaries(:tls_124_by_alice))
    end

    assert_redirected_to login_path
  end
end
