# frozen_string_literal: true

require "test_helper"

class Admin::DatatrackerImportsControllerTest < ActionDispatch::IntegrationTest
  include AuthTestHelper

  # === Authentication/Authorization ===

  test "unauthenticated user is redirected to login" do
    get admin_datatracker_imports_url
    assert_redirected_to login_path
  end

  test "non-admin user is redirected to root" do
    sign_in_as(users(:bob))
    get admin_datatracker_imports_url
    assert_redirected_to "/"
  end

  test "admin user can access the imports page" do
    sign_in_as(users(:alice))
    get admin_datatracker_imports_url
    assert_response :success
  end

  test "non-admin cannot trigger import_groups" do
    sign_in_as(users(:bob))
    post import_groups_admin_datatracker_imports_path, params: { state: "active" }
    assert_redirected_to "/"
  end

  test "non-admin cannot trigger delete_meeting" do
    sign_in_as(users(:bob))
    post delete_meeting_admin_datatracker_imports_path, params: { meeting_number: "124" }
    assert_redirected_to "/"
  end

  # === Import Groups ===

  test "import_groups enqueues ImportGroupsJob" do
    sign_in_as(users(:alice))
    assert_enqueued_with(job: ImportGroupsJob) do
      post import_groups_admin_datatracker_imports_path, params: { state: "active" }
    end
    assert_redirected_to admin_datatracker_imports_path
    assert_match(/Import groups job enqueued/, flash[:notice])
  end

  test "import_groups enqueues with custom state and type" do
    sign_in_as(users(:alice))
    assert_enqueued_with(job: ImportGroupsJob) do
      post import_groups_admin_datatracker_imports_path, params: { state: "concluded", type: "wg" }
    end
    assert_redirected_to admin_datatracker_imports_path
  end

  # === Import Meeting ===

  test "import_meeting requires meeting_number" do
    sign_in_as(users(:alice))
    post import_meeting_admin_datatracker_imports_path, params: { meeting_number: "" }
    assert_redirected_to admin_datatracker_imports_path
    assert_equal "Meeting number is required.", flash[:alert]
  end

  test "import_meeting enqueues ImportMeetingJob" do
    sign_in_as(users(:alice))
    assert_enqueued_with(job: ImportMeetingJob) do
      post import_meeting_admin_datatracker_imports_path, params: { meeting_number: "124" }
    end
    assert_redirected_to admin_datatracker_imports_path
    assert_match(/Import meeting 124/, flash[:notice])
  end

  # === Import Sessions ===

  test "import_sessions requires meeting_number" do
    sign_in_as(users(:alice))
    post import_sessions_admin_datatracker_imports_path, params: { meeting_number: "" }
    assert_redirected_to admin_datatracker_imports_path
    assert_equal "Meeting number is required.", flash[:alert]
  end

  test "import_sessions enqueues ImportSessionsJob" do
    sign_in_as(users(:alice))
    assert_enqueued_with(job: ImportSessionsJob) do
      post import_sessions_admin_datatracker_imports_path, params: { meeting_number: "124" }
    end
    assert_redirected_to admin_datatracker_imports_path
    assert_match(/Import sessions for meeting 124/, flash[:notice])
  end

  # === Import Presentations ===

  test "import_presentations requires meeting_number" do
    sign_in_as(users(:alice))
    post import_presentations_admin_datatracker_imports_path, params: { meeting_number: "" }
    assert_redirected_to admin_datatracker_imports_path
    assert_equal "Meeting number is required.", flash[:alert]
  end

  test "import_presentations enqueues ImportPresentationsJob" do
    sign_in_as(users(:alice))
    assert_enqueued_with(job: ImportPresentationsJob) do
      post import_presentations_admin_datatracker_imports_path, params: { meeting_number: "124" }
    end
    assert_redirected_to admin_datatracker_imports_path
  end

  test "import_presentations enqueues with optional group" do
    sign_in_as(users(:alice))
    assert_enqueued_with(job: ImportPresentationsJob) do
      post import_presentations_admin_datatracker_imports_path,
        params: { meeting_number: "124", group_acronym: "tls" }
    end
    assert_redirected_to admin_datatracker_imports_path
    assert_match(/group: tls/, flash[:notice])
  end

  # === Full Import ===

  test "import_all requires meeting_number" do
    sign_in_as(users(:alice))
    post import_all_admin_datatracker_imports_path, params: { meeting_number: "" }
    assert_redirected_to admin_datatracker_imports_path
    assert_equal "Meeting number is required.", flash[:alert]
  end

  test "import_all enqueues FullImportJob" do
    sign_in_as(users(:alice))
    assert_enqueued_with(job: FullImportJob) do
      post import_all_admin_datatracker_imports_path, params: { meeting_number: "124" }
    end
    assert_redirected_to admin_datatracker_imports_path
    assert_match(/Full import for meeting 124/, flash[:notice])
  end

  # === Delete Meeting ===

  test "delete_meeting requires meeting_number" do
    sign_in_as(users(:alice))
    post delete_meeting_admin_datatracker_imports_path, params: { meeting_number: "" }
    assert_redirected_to admin_datatracker_imports_path
    assert_equal "Meeting number is required.", flash[:alert]
  end

  test "delete_meeting with nonexistent meeting shows error" do
    sign_in_as(users(:alice))
    post delete_meeting_admin_datatracker_imports_path, params: { meeting_number: "999" }
    assert_redirected_to admin_datatracker_imports_path
    assert_match(/not found/, flash[:alert])
  end

  test "delete_meeting destroys meeting and redirects with stats" do
    sign_in_as(users(:alice))
    meeting = meetings(:ietf124)
    post delete_meeting_admin_datatracker_imports_path, params: { meeting_number: meeting.number }
    assert_redirected_to admin_datatracker_imports_path
    assert_match(/Deleted meeting/, flash[:notice])
    assert_nil Meeting.find_by(number: meeting.number)
  end
end
