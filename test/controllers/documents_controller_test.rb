# frozen_string_literal: true

require "test_helper"

class DocumentsControllerTest < ActionDispatch::IntegrationTest
  include AuthTestHelper

  setup do
    sign_in_as(users(:alice))
  end

  test "should get index" do
    get documents_url
    assert_response :success
  end

  test "should get show" do
    get document_url(documents(:tls_agenda))
    assert_response :success
  end

  test "show page should contain upload form" do
    get document_url(documents(:tls_agenda))
    assert_select "form[action=?]", document_document_material_path(documents(:tls_agenda))
    assert_select "input[type=file]"
  end
end
