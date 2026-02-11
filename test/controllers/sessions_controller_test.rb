# frozen_string_literal: true

require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  include AuthTestHelper

  setup do
    sign_in_as(users(:alice))
  end

  test "should get index" do
    get sessions_url
    assert_response :success
  end
end
