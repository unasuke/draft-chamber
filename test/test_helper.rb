ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/mock"

OmniAuth.config.test_mode = true

module AuthTestHelper
  def sign_in_as(user)
    github_auth = user.github_authentication
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
      provider: "github",
      uid: github_auth.uid,
      info: {
        nickname: github_auth.nickname,
        name: github_auth.name,
        email: github_auth.email,
        image: github_auth.avatar_url
      }
    )
    get "/auth/github/callback"
  end
end

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
