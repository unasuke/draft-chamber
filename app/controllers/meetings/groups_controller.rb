# frozen_string_literal: true

module Meetings
  class GroupsController < ApplicationController
    def show
      @meeting = Meeting.find_by!(number: params[:meeting_id])
      @group = Group.find_by!(acronym: params[:id])
      @documents = Document.joins(session_presentations: :session)
        .where(sessions: { meeting_id: @meeting.id, group_id: @group.id })
        .includes(:document_material)
        .distinct
        .order(:name)
    end
  end
end
