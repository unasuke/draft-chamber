# frozen_string_literal: true

require "test_helper"

class RootPageControllerTest < ActionDispatch::IntegrationTest
  include AuthTestHelper

  test "should get index without login" do
    get root_url
    assert_response :success
  end

  test "index shows login button when not logged in" do
    get root_url
    assert_select "button", "Sign in with GitHub"
  end

  test "index does not show MCP setup when not logged in" do
    get root_url
    assert_select "h2", { text: "MCP Server Setup", count: 0 }
  end

  test "index shows MCP setup when logged in" do
    sign_in_as(users(:alice))
    get root_url
    assert_response :success
    assert_select "h2", "MCP Server Setup"
    assert_select "code", %r{/mcp}
  end

  test "index shows footer" do
    get root_url
    assert_select "footer"
    assert_select "a[href=?]", "https://trustee.ietf.org/"
  end

  test "hides navigation bar when not logged in" do
    get root_url
    assert_select "nav.bg-ietf-blue", count: 0
  end

  test "shows navigation bar when logged in" do
    sign_in_as(users(:alice))
    get root_url
    assert_select "nav.bg-ietf-blue"
  end
end
