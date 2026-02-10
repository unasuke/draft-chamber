# frozen_string_literal: true

require "test_helper"

class SessionPresentationsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get session_presentations_url
    assert_response :success
  end
end
