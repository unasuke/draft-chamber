# frozen_string_literal: true

require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "find_or_create_from_omniauth creates new user with github authentication" do
    auth = OmniAuth::AuthHash.new(
      provider: "github",
      uid: "99999",
      info: {
        nickname: "newuser",
        name: "New User",
        email: "new@example.com",
        image: "https://avatars.githubusercontent.com/u/99999"
      }
    )

    assert_difference [ "User.count", "GithubAuthentication.count" ], 1 do
      user = User.find_or_create_from_omniauth(auth)
      assert_equal "newuser", user.nickname
      assert_equal "99999", user.github_authentication.uid
    end
  end

  test "find_or_create_from_omniauth returns existing user and updates profile" do
    user = users(:alice)
    auth = OmniAuth::AuthHash.new(
      provider: "github",
      uid: user.github_authentication.uid,
      info: {
        nickname: "alice_updated",
        name: "Alice Updated",
        email: "alice_new@example.com",
        image: "https://avatars.githubusercontent.com/u/12345"
      }
    )

    assert_no_difference [ "User.count", "GithubAuthentication.count" ] do
      found_user = User.find_or_create_from_omniauth(auth)
      assert_equal user.id, found_user.id
      assert_equal "alice_updated", found_user.nickname
    end
  end

  test "delegates profile attributes to github_authentication" do
    user = users(:alice)
    assert_equal "alice", user.nickname
    assert_equal "Alice", user.name
    assert_equal "alice@example.com", user.email
  end
end
