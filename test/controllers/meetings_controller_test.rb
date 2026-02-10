# frozen_string_literal: true

require "test_helper"

class MeetingsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get meetings_url
    assert_response :success
  end
end
