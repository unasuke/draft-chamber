# frozen_string_literal: true

class TrackedDraft < ApplicationRecord
  belongs_to :document, optional: true

  enum :status, {
    active: "active",
    archived: "archived"
  }

  validates :draft_name, presence: true, uniqueness: true
end
