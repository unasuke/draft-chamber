# frozen_string_literal: true

class Meeting < ApplicationRecord
  has_many :sessions, dependent: :destroy

  validates :number, presence: true, uniqueness: true
  validates :resource_uri, presence: true, uniqueness: true

  enum :meeting_type, {
    ietf: "ietf",
    interim: "interim"
  }

  scope :recent, -> { order(date: :desc) }

  def to_s
    number
  end
end
