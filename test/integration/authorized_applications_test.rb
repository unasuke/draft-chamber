# frozen_string_literal: true

require "test_helper"

class AuthorizedApplicationsTest < ActionDispatch::IntegrationTest
  include AuthTestHelper

  setup do
    sign_in_as(users(:alice))
  end

  test "shows authorized applications page" do
    get oauth_authorized_applications_path
    assert_response :success
    assert_select "h1", t("doorkeeper.authorized_applications.index.title")
  end

  test "lists authorized applications" do
    app = Doorkeeper::Application.create!(
      name: "Test MCP Client",
      redirect_uri: "https://example.com/callback",
      confidential: false,
      scopes: "mcp"
    )
    Doorkeeper::AccessToken.create!(
      application: app,
      resource_owner_id: users(:alice).id,
      scopes: "mcp",
      expires_in: 1.hour
    )

    get oauth_authorized_applications_path
    assert_response :success
    assert_select "td", "Test MCP Client"
  end

  test "does not list applications authorized by other users" do
    app = Doorkeeper::Application.create!(
      name: "Bob Client",
      redirect_uri: "https://example.com/callback",
      confidential: false,
      scopes: "mcp"
    )
    Doorkeeper::AccessToken.create!(
      application: app,
      resource_owner_id: users(:bob).id,
      scopes: "mcp",
      expires_in: 1.hour
    )

    get oauth_authorized_applications_path
    assert_response :success
    assert_select "td", text: "Bob Client", count: 0
  end

  test "revokes authorized application" do
    app = Doorkeeper::Application.create!(
      name: "Revokable Client",
      redirect_uri: "https://example.com/callback",
      confidential: false,
      scopes: "mcp"
    )
    Doorkeeper::AccessToken.create!(
      application: app,
      resource_owner_id: users(:alice).id,
      scopes: "mcp",
      expires_in: 1.hour
    )

    delete oauth_authorized_application_path(app)
    assert_redirected_to oauth_authorized_applications_url

    get oauth_authorized_applications_path
    assert_select "td", text: "Revokable Client", count: 0
  end

  test "shows empty state when no authorized applications" do
    get oauth_authorized_applications_path
    assert_response :success
    assert_select "p", "No authorized applications."
  end

  private

  def t(key, **options)
    I18n.t(key, **options)
  end
end
