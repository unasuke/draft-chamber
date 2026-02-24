# frozen_string_literal: true

class FullImportJob < ApplicationJob
  include DatatrackerImportJob

  def perform(meeting_number)
    DatatrackerImport::FullImport.new.import_meeting(meeting_number: meeting_number)
  end
end
