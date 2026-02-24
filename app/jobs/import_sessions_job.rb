# frozen_string_literal: true

class ImportSessionsJob < ApplicationJob
  include DatatrackerImportJob

  def perform(meeting_number)
    DatatrackerImport::SessionImporter.new.import(meeting_number: meeting_number)
  end
end
