# frozen_string_literal: true

class ImportMeetingJob < ApplicationJob
  include DatatrackerImportJob

  def perform(meeting_number)
    DatatrackerImport::MeetingImporter.new.import(number: meeting_number)
  end
end
