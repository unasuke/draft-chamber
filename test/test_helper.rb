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

module OAuthTestHelper
  def create_access_token(user:, scopes: "mcp", resource: nil)
    app = Doorkeeper::Application.create!(
      name: "Test Client",
      redirect_uri: "https://example.com/callback",
      confidential: false,
      scopes: scopes
    )
    token = Doorkeeper::AccessToken.create!(
      application: app,
      resource_owner_id: user.id,
      scopes: scopes,
      expires_in: 1.hour,
      resource: resource
    )
    token.plaintext_token
  end

  def bearer_headers(token)
    {
      "Content-Type" => "application/json",
      "Accept" => "application/json, text/event-stream",
      "Authorization" => "Bearer #{token}"
    }
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
