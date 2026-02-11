# frozen_string_literal: true

require "test_helper"

module Meetings
  class GroupsControllerTest < ActionDispatch::IntegrationTest
    include AuthTestHelper

    setup do
      sign_in_as(users(:alice))
    end

    test "should get show" do
      get meeting_group_url(meetings(:ietf124), groups(:tls))
      assert_response :success
    end

    test "show page should list documents from session presentations" do
      get meeting_group_url(meetings(:ietf124), groups(:tls))
      assert_select "a[href=?]", document_path(documents(:tls_chairs_slides))
      assert_select "a[href=?]", document_path(documents(:tls_agenda))
      assert_select "a[href=?]", document_path(documents(:tls_minutes))
    end

    test "show page should have breadcrumb navigation" do
      get meeting_group_url(meetings(:ietf124), groups(:tls))
      assert_select "a[href=?]", meetings_path
      assert_select "a[href=?]", meeting_path(meetings(:ietf124))
    end

    test "show page should display download link for document with material" do
      document = documents(:tls_chairs_slides)
      material = document.create_document_material!(download_status: :pending)
      material.file.attach(
        io: StringIO.new("test content"),
        filename: "slides-124-tls-chairs.pdf",
        content_type: "application/pdf"
      )
      material.update!(download_status: :completed)

      get meeting_group_url(meetings(:ietf124), groups(:tls))
      assert_select "a[data-bulk-download-target='link']", text: "Download"
    end

    test "show page should display bulk download button when materials exist" do
      document = documents(:tls_chairs_slides)
      material = document.create_document_material!(download_status: :pending)
      material.file.attach(
        io: StringIO.new("test content"),
        filename: "slides-124-tls-chairs.pdf",
        content_type: "application/pdf"
      )
      material.update!(download_status: :completed)

      get meeting_group_url(meetings(:ietf124), groups(:tls))
      assert_select "button[data-action='click->bulk-download#downloadAll']", text: "Download All Materials"
    end

    test "show page should not display bulk download button when no materials exist" do
      get meeting_group_url(meetings(:ietf124), groups(:tls))
      assert_select "button[data-action='click->bulk-download#downloadAll']", false
    end
  end
end
