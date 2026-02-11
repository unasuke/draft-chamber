# frozen_string_literal: true

require "test_helper"

class GithubAuthenticationTest < ActiveSupport::TestCase
  test "validates uid presence" do
    auth = GithubAuthentication.new(user: User.new, nickname: "test")
    assert_not auth.valid?
    assert_includes auth.errors[:uid], "can't be blank"
  end

  test "validates uid uniqueness" do
    existing = github_authentications(:alice)
    auth = GithubAuthentication.new(user: User.create!, uid: existing.uid, nickname: "test")
    assert_not auth.valid?
    assert_includes auth.errors[:uid], "has already been taken"
  end

  test "validates nickname presence" do
    auth = GithubAuthentication.new(user: User.new, uid: "unique-uid")
    assert_not auth.valid?
    assert_includes auth.errors[:nickname], "can't be blank"
  end
end
