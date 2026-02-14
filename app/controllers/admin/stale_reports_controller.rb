# frozen_string_literal: true

module Admin
  class StaleReportsController < BaseController
    def index
      @pagy, @stale_reports = pagy(
        StaleReport.includes(:reportable, :user).recent
      )
    end

    def acknowledge
      @stale_report = StaleReport.find(params[:id])
      @stale_report.acknowledged!
      redirect_to admin_stale_reports_path, notice: "Report acknowledged."
    end

    def resolve
      @stale_report = StaleReport.find(params[:id])
      @stale_report.resolved!
      redirect_to admin_stale_reports_path, notice: "Report resolved."
    end
  end
end
