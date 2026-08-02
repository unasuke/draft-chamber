# frozen_string_literal: true

require "test_helper"

class SummaryTest < ActiveSupport::TestCase
  def build_summary(**attributes)
    Summary.new({
      session: sessions(:tls_at_124),
      user: users(:alice),
      client_name: "Claude Code",
      meeting_number: "124",
      group_acronym: "tls",
      title: "TLS WG",
      body: "# TLS WG"
    }.merge(attributes))
  end

  test "valid summary" do
    assert build_summary.valid?
  end

  test "generates a 24 character public_token" do
    summary = build_summary
    summary.save!

    assert_equal 24, summary.public_token.length
  end

  test "public_token is unique across summaries" do
    tokens = 3.times.map { build_summary.tap(&:save!).public_token }
    assert_equal 3, tokens.uniq.size
  end

  test "requires title" do
    assert_not build_summary(title: nil).valid?
  end

  test "rejects title longer than 255 characters" do
    assert_not build_summary(title: "a" * 256).valid?
    assert build_summary(title: "a" * 255).valid?
  end

  test "requires body" do
    assert_not build_summary(body: nil).valid?
  end

  test "requires meeting_number" do
    assert_not build_summary(meeting_number: nil).valid?
  end

  test "requires client_name" do
    assert_not build_summary(client_name: nil).valid?
  end

  test "requires user" do
    assert_not build_summary(user: nil).valid?
  end

  test "session is optional" do
    assert build_summary(session: nil).valid?
  end

  test "oauth_application is optional" do
    assert build_summary(oauth_application: nil).valid?
  end

  test "orphaned? is true when session is missing" do
    assert summaries(:orphaned).orphaned?
    assert_not summaries(:tls_124_by_alice).orphaned?
  end

  test "linked scope excludes orphans" do
    assert_not_includes Summary.linked, summaries(:orphaned)
    assert_includes Summary.linked, summaries(:tls_124_by_alice)
  end

  test "recent scope orders by created_at descending" do
    older = build_summary.tap { |s| s.save!; s.update_column(:created_at, 2.days.ago) }
    newer = build_summary.tap { |s| s.save!; s.update_column(:created_at, 1.day.ago) }

    ordered = Summary.where(id: [ older.id, newer.id ]).recent
    assert_equal [ newer, older ], ordered.to_a
  end

  test "destroying a session nullifies the summary instead of deleting it" do
    summary = summaries(:tls_124_by_alice)

    sessions(:tls_at_124).destroy!

    assert Summary.exists?(summary.id)
    assert_nil summary.reload.session_id
    assert_equal "124", summary.meeting_number
  end

  test "destroying a user destroys their summaries" do
    summary = summaries(:tls_124_by_bob)

    users(:bob).destroy!

    assert_not Summary.exists?(summary.id)
  end

  test "public_url uses APP_HOST over https when set" do
    summary = summaries(:tls_124_by_alice)

    with_app_host("draft-chamber.example.invalid") do
      assert_equal "https://draft-chamber.example.invalid/s/#{summary.public_token}", summary.public_url
    end
  end

  test "public_url falls back to localhost over http" do
    summary = summaries(:tls_124_by_alice)

    with_app_host(nil) do
      assert_equal "http://localhost:3000/s/#{summary.public_token}", summary.public_url
    end
  end

  private

  def with_app_host(host)
    original = ENV["APP_HOST"]
    ENV["APP_HOST"] = host
    yield
  ensure
    ENV["APP_HOST"] = original
  end
end
