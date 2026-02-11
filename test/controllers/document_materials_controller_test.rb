# frozen_string_literal: true

require "test_helper"

class DocumentMaterialsControllerTest < ActionDispatch::IntegrationTest
  include AuthTestHelper

  setup do
    sign_in_as(users(:alice))
    @document_without_material = documents(:tls_agenda)
    @document_with_material = documents(:tls_draft)
  end

  test "should create material with valid file" do
    assert_difference "DocumentMaterial.count", 1 do
      post document_document_material_url(@document_without_material),
        params: { file: fixture_file_upload("sample_document.txt", "text/plain") }
    end

    assert_redirected_to document_url(@document_without_material)

    material = @document_without_material.reload.document_material
    assert material.file.attached?
    assert_equal "completed", material.download_status
    assert_equal "text/plain", material.content_type
    assert_equal "sample_document.txt", material.filename
    assert_not_nil material.downloaded_at
  end

  test "should create DocumentMaterialUploadedBy record on upload" do
    assert_difference "DocumentMaterialUploadedBy.count", 1 do
      post document_document_material_url(@document_without_material),
        params: { file: fixture_file_upload("sample_document.txt", "text/plain") }
    end

    uploaded_by = @document_without_material.reload.document_material.document_material_uploaded_bys.last
    assert_equal users(:alice), uploaded_by.user
  end

  test "should replace existing material without increasing count" do
    assert_no_difference "DocumentMaterial.count" do
      post document_document_material_url(@document_with_material),
        params: { file: fixture_file_upload("sample_document.txt", "text/plain") }
    end

    assert_redirected_to document_url(@document_with_material)

    material = @document_with_material.reload.document_material
    assert_equal "text/plain", material.content_type
    assert_equal "sample_document.txt", material.filename
  end

  test "should add new upload history on replacement" do
    assert_difference "DocumentMaterialUploadedBy.count", 1 do
      post document_document_material_url(@document_with_material),
        params: { file: fixture_file_upload("sample_document.txt", "text/plain") }
    end
  end

  test "should set download_status to completed" do
    post document_document_material_url(@document_without_material),
      params: { file: fixture_file_upload("sample_document.txt", "text/plain") }

    assert_equal "completed", @document_without_material.reload.document_material.download_status
  end

  test "should clear download_error on upload" do
    material = @document_with_material.document_material
    material.update!(download_status: :failed, download_error: "some error")

    post document_document_material_url(@document_with_material),
      params: { file: fixture_file_upload("sample_document.txt", "text/plain") }

    material.reload
    assert_nil material.download_error
    assert_equal "completed", material.download_status
  end

  test "should destroy material" do
    assert_difference "DocumentMaterial.count", -1 do
      delete document_document_material_url(@document_with_material)
    end

    assert_redirected_to document_url(@document_with_material)
  end

  test "should handle destroy when no material exists" do
    assert_no_difference "DocumentMaterial.count" do
      delete document_document_material_url(@document_without_material)
    end

    assert_redirected_to document_url(@document_without_material)
  end
end
