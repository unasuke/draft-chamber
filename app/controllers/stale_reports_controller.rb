# frozen_string_literal: true

class StaleReportsController < ApplicationController
  def create
    reportable = find_reportable
    @stale_report = StaleReport.new(
      reportable: reportable,
      user: current_user,
      message: params.dig(:stale_report, :message)
    )

    if @stale_report.save
      redirect_back fallback_location: root_path, notice: "Thank you for reporting stale data."
    else
      redirect_back fallback_location: root_path, alert: @stale_report.errors.full_messages.to_sentence
    end
  end

  private

  def find_reportable
    if params[:meeting_id] && params[:group_id]
      Group.find_by!(acronym: params[:group_id])
    elsif params[:meeting_id]
      Meeting.find_by!(number: params[:meeting_id])
    elsif params[:document_id]
      Document.find(params[:document_id])
    else
      raise ActiveRecord::RecordNotFound
    end
  end
end
