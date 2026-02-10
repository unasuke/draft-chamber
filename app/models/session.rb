# frozen_string_literal: true

class Session < ApplicationRecord
  belongs_to :meeting
  belongs_to :group, optional: true
  has_many :session_presentations, dependent: :destroy
  has_many :documents, through: :session_presentations

  validates :resource_uri, presence: true, uniqueness: true
  validates :datatracker_id, uniqueness: true, allow_nil: true
end
