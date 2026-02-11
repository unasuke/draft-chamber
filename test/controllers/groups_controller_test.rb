# frozen_string_literal: true

require "test_helper"

class GroupsControllerTest < ActionDispatch::IntegrationTest
  include AuthTestHelper

  setup do
    sign_in_as(users(:alice))
  end

  test "should get index" do
    get groups_url
    assert_response :success
  end
end
