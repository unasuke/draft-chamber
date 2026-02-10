# frozen_string_literal: true

class SessionPresentation < ApplicationRecord
  belongs_to :session
  belongs_to :document

  validates :resource_uri, presence: true, uniqueness: true
  validates :session_id, uniqueness: { scope: :document_id }

  scope :ordered, -> { order(:order) }
end
