# frozen_string_literal: true

require "test_helper"

class StaleReportTest < ActiveSupport::TestCase
  test "valid stale report" do
    report = StaleReport.new(
      reportable: meetings(:ietf124),
      user: users(:bob),
      message: "Data seems outdated"
    )
    assert report.valid?
  end

  test "requires reportable" do
    report = StaleReport.new(user: users(:bob))
    assert_not report.valid?
  end

  test "requires user" do
    report = StaleReport.new(reportable: meetings(:ietf124))
    assert_not report.valid?
  end

  test "default status is pending" do
    report = StaleReport.new(reportable: meetings(:ietf124), user: users(:bob))
    assert_equal "pending", report.status
  end

  test "prevents duplicate pending reports for same resource by same user" do
    StaleReport.create!(reportable: meetings(:ietf124), user: users(:bob))
    duplicate = StaleReport.new(reportable: meetings(:ietf124), user: users(:bob))
    assert_not duplicate.valid?
  end

  test "allows new report after previous one is resolved" do
    report = StaleReport.create!(reportable: meetings(:ietf124), user: users(:bob))
    report.resolved!
    new_report = StaleReport.new(reportable: meetings(:ietf124), user: users(:bob))
    assert new_report.valid?
  end

  test "different users can report the same resource" do
    StaleReport.create!(reportable: meetings(:ietf124), user: users(:alice))
    report = StaleReport.new(reportable: meetings(:ietf124), user: users(:bob))
    assert report.valid?
  end

  test "status transitions" do
    report = StaleReport.create!(reportable: meetings(:ietf124), user: users(:bob))
    assert report.pending?
    report.acknowledged!
    assert report.acknowledged?
    report.resolved!
    assert report.resolved?
  end

  test "message is optional" do
    report = StaleReport.new(reportable: meetings(:ietf124), user: users(:bob), message: nil)
    assert report.valid?
  end

  test "can report different resource types" do
    meeting_report = StaleReport.new(reportable: meetings(:ietf124), user: users(:bob))
    assert meeting_report.valid?

    document_report = StaleReport.new(reportable: documents(:tls_chairs_slides), user: users(:bob))
    assert document_report.valid?

    group_report = StaleReport.new(reportable: groups(:tls), user: users(:bob))
    assert group_report.valid?
  end
end
