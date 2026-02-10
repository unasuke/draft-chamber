# frozen_string_literal: true

class DocumentMaterial < ApplicationRecord
  include Attachable

  belongs_to :document

  enum :download_status, {
    pending: "pending",
    downloading: "downloading",
    completed: "completed",
    failed: "failed"
  }

  validates :document_id, uniqueness: true

  def file_required?
    completed?
  end
end
