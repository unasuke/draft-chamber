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
  end
end
