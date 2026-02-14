# frozen_string_literal: true

class Meeting < ApplicationRecord
  has_many :sessions, dependent: :destroy
  has_many :stale_reports, as: :reportable, dependent: :destroy

  validates :number, presence: true, uniqueness: true
  validates :resource_uri, presence: true, uniqueness: true

  enum :meeting_type, {
    ietf: "ietf",
    interim: "interim"
  }

  scope :recent, -> { order(date: :desc) }
  scope :syncable, -> { where("date(date, '+' || days || ' days') >= ?", 30.days.ago.to_date.iso8601) }

  def to_param
    number
  end

  def to_s
    number
  end
end
