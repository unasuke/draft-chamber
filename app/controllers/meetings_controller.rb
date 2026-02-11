# frozen_string_literal: true

class MeetingsController < ApplicationController
  def index
    @pagy, @meetings = pagy(Meeting.recent)
  end

  def show
    @meeting = Meeting.find_by!(number: params[:id])
    @groups = Group.joins(:sessions).where(sessions: { meeting_id: @meeting.id }).distinct.order(:acronym)
  end
end
