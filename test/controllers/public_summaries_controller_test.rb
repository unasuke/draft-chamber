# frozen_string_literal: true

require "test_helper"

class PublicSummariesControllerTest < ActionDispatch::IntegrationTest
  include AuthTestHelper

  test "show is readable without logging in" do
    get public_summary_url(summaries(:tls_124_by_alice).public_token)

    assert_response :success
    assert_select "h1", text: "TLS WG at IETF 124"
    assert_select ".markdown-body li", text: "Encrypted Client Hello deployment status"
  end

  test "show displays the author nickname" do
    get public_summary_url(summaries(:tls_124_by_alice).public_token)

    assert_response :success
    assert_match "@alice", response.body
  end

  test "show displays the generating client" do
    get public_summary_url(summaries(:tls_124_by_alice).public_token)

    assert_match "Claude Code", response.body
  end

  test "show renders without the site navigation" do
    get public_summary_url(summaries(:tls_124_by_alice).public_token)

    assert_select "nav[data-controller=mobile-menu]", count: 0
    assert_select "a[href=?]", meetings_path, count: 0
  end

  test "show renders without the site navigation even when signed in" do
    sign_in_as(users(:alice))

    get public_summary_url(summaries(:tls_124_by_alice).public_token)

    assert_select "nav[data-controller=mobile-menu]", count: 0
    assert_select "a[href=?]", summaries_path, count: 0
  end

  test "show keeps the footer" do
    get public_summary_url(summaries(:tls_124_by_alice).public_token)

    assert_select "footer"
  end

  test "show sets noindex" do
    get public_summary_url(summaries(:tls_124_by_alice).public_token)

    assert_select "meta[name=robots][content=?]", "noindex, nofollow"
  end

  test "show renders an orphaned summary with a notice" do
    get public_summary_url(summaries(:orphaned).public_token)

    assert_response :success
    assert_match "no longer in the database", response.body
  end

  test "show returns 404 for an unknown token" do
    get public_summary_url("nosuchtoken000000000000x")

    assert_response :not_found
  end

  test "show hides the delete button from signed out visitors" do
    summary = summaries(:tls_124_by_alice)

    get public_summary_url(summary.public_token)

    assert_select "form[action=?]", summary_path(summary), count: 0
  end

  test "show hides the delete button from other users" do
    sign_in_as(users(:bob))
    summary = summaries(:tls_124_by_alice)

    get public_summary_url(summary.public_token)

    assert_select "form[action=?]", summary_path(summary), count: 0
  end

  test "show offers the delete button to the author" do
    sign_in_as(users(:alice))
    summary = summaries(:tls_124_by_alice)

    get public_summary_url(summary.public_token)

    assert_select "form[action=?]", summary_path(summary)
  end

  test "show offers the delete button to an admin" do
    sign_in_as(users(:alice))
    summary = summaries(:tls_124_by_bob)

    assert_predicate users(:alice), :admin?
    get public_summary_url(summary.public_token)

    assert_select "form[action=?]", summary_path(summary)
  end
end
