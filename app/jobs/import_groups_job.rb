# frozen_string_literal: true

class ImportGroupsJob < ApplicationJob
  include DatatrackerImportJob

  def perform(state: "active", type: nil)
    params = { state: state }
    params[:type] = type if type
    DatatrackerImport::GroupImporter.new.import(params)
  end
end
