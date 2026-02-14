# frozen_string_literal: true

class StaleReport < ApplicationRecord
  belongs_to :reportable, polymorphic: true
  belongs_to :user

  enum :status, {
    pending: "pending",
    acknowledged: "acknowledged",
    resolved: "resolved"
  }

  validates :status, presence: true
  validates :user_id, uniqueness: {
    scope: [ :reportable_type, :reportable_id ],
    conditions: -> { where(status: "pending") },
    message: "has already reported this resource as stale"
  }

  scope :recent, -> { order(created_at: :desc) }
end
