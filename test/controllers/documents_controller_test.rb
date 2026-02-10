# frozen_string_literal: true

require "test_helper"

class DocumentsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get documents_url
    assert_response :success
  end
end
