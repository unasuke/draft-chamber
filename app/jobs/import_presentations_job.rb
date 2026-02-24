# frozen_string_literal: true

class ImportPresentationsJob < ApplicationJob
  include DatatrackerImportJob

  def perform(meeting_number, group_acronym: nil)
    DatatrackerImport::SessionPresentationImporter.new
      .import(meeting_number: meeting_number, group_acronym: group_acronym)
  end
end
