# frozen_string_literal: true

module Admin
  class DatatrackerImportsController < BaseController
    def index
      @meetings = Meeting.recent.limit(20)
    end

    def import_groups
      state = params[:state].presence || "active"
      type = params[:type].presence
      ImportGroupsJob.perform_later(state: state, type: type)
      redirect_to admin_datatracker_imports_path,
        notice: "Import groups job enqueued (state: #{state}#{type ? ", type: #{type}" : ""})."
    end

    def import_meeting
      meeting_number = params[:meeting_number].presence
      return redirect_missing_meeting_number unless meeting_number

      ImportMeetingJob.perform_later(meeting_number)
      redirect_to admin_datatracker_imports_path,
        notice: "Import meeting #{meeting_number} job enqueued."
    end

    def import_sessions
      meeting_number = params[:meeting_number].presence
      return redirect_missing_meeting_number unless meeting_number

      ImportSessionsJob.perform_later(meeting_number)
      redirect_to admin_datatracker_imports_path,
        notice: "Import sessions for meeting #{meeting_number} job enqueued."
    end

    def import_presentations
      meeting_number = params[:meeting_number].presence
      return redirect_missing_meeting_number unless meeting_number

      group_acronym = params[:group_acronym].presence
      ImportPresentationsJob.perform_later(meeting_number, group_acronym: group_acronym)
      redirect_to admin_datatracker_imports_path,
        notice: "Import presentations for meeting #{meeting_number}#{group_acronym ? " (group: #{group_acronym})" : ""} job enqueued."
    end

    def import_all
      meeting_number = params[:meeting_number].presence
      return redirect_missing_meeting_number unless meeting_number

      FullImportJob.perform_later(meeting_number)
      redirect_to admin_datatracker_imports_path,
        notice: "Full import for meeting #{meeting_number} job enqueued."
    end

    def delete_meeting
      meeting_number = params[:meeting_number].presence
      return redirect_missing_meeting_number unless meeting_number

      meeting = Meeting.find_by(number: meeting_number)
      unless meeting
        return redirect_to admin_datatracker_imports_path,
          alert: "Meeting #{meeting_number} not found."
      end

      document_ids = Document.joins(:session_presentations)
        .where(session_presentations: { session_id: meeting.session_ids })
        .distinct.pluck(:id)
      sessions_count = meeting.sessions.count
      presentations_count = SessionPresentation.where(session_id: meeting.session_ids).count

      meeting.destroy!

      orphaned_ids = document_ids - SessionPresentation.where(document_id: document_ids).distinct.pluck(:document_id)
      orphaned_count = Document.where(id: orphaned_ids).destroy_all.count

      redirect_to admin_datatracker_imports_path,
        notice: "Deleted meeting #{meeting_number}: #{sessions_count} sessions, " \
                "#{presentations_count} presentations, #{orphaned_count} orphaned documents removed."
    end

    private

    def redirect_missing_meeting_number
      redirect_to admin_datatracker_imports_path, alert: "Meeting number is required."
    end
  end
end
