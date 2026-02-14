# frozen_string_literal: true

module Admin
  class DashboardController < BaseController
    def index
      @stats = {
        meetings: Meeting.count,
        sessions: Session.count,
        documents: Document.count,
        groups: Group.count,
        users: User.count
      }

      @download_status_counts = DocumentMaterial.group(:download_status).count
      @processing_status_counts = DocumentMaterial.group(:processing_status).count

      @recent_materials = DocumentMaterial.includes(:document)
        .where.not(downloaded_at: nil)
        .order(downloaded_at: :desc)
        .limit(10)
    end
  end
end
