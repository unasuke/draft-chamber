# frozen_string_literal: true

require "test_helper"

class Auth::SessionsControllerTest < ActionDispatch::IntegrationTest
  include AuthTestHelper

  test "create logs in user via github callback" do
    sign_in_as(users(:alice))
    assert_redirected_to root_path
    follow_redirect!
    assert_response :success
  end

  test "create creates new user for unknown github account" do
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
      provider: "github",
      uid: "999999",
      info: {
        nickname: "newcomer",
        name: "New Comer",
        email: "newcomer@example.com",
        image: nil
      }
    )

    assert_difference [ "User.count", "GithubAuthentication.count" ], 1 do
      get "/auth/github/callback"
    end
    assert_redirected_to root_path
  end

  test "destroy clears session" do
    sign_in_as(users(:alice))
    delete logout_path
    assert_redirected_to root_path

    get meetings_path
    assert_redirected_to login_path
  end

  test "new renders login page" do
    get login_path
    assert_response :success
  end
end
