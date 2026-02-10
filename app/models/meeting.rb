# frozen_string_literal: true

class Meeting < ApplicationRecord
  has_many :sessions, dependent: :destroy

  validates :number, presence: true, uniqueness: true
  validates :resource_uri, presence: true, uniqueness: true

  scope :ietf, -> { where(meeting_type: "ietf") }
  scope :interim, -> { where(meeting_type: "interim") }
  scope :recent, -> { order(date: :desc) }

  def to_s
    number
  end
end
