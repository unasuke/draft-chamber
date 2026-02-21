# frozen_string_literal: true

class Document < ApplicationRecord
  belongs_to :group, optional: true
  has_one :document_material, dependent: :destroy
  has_many :session_presentations, dependent: :destroy
  has_many :sessions, through: :session_presentations
  has_many :stale_reports, as: :reportable, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :resource_uri, presence: true, uniqueness: true

  scope :search_by_name, ->(query) { where("name LIKE ?", "%#{sanitize_sql_like(query)}%") }

  enum :document_type, {
    agenda: "agenda",
    bcp: "bcp",
    bluesheets: "bluesheets",
    bofreq: "bofreq",
    charter: "charter",
    chatlog: "chatlog",
    conflrev: "conflrev",
    draft: "draft",
    fyi: "fyi",
    liaison: "liaison",
    liai_att: "liai-att",
    minutes: "minutes",
    narrativeminutes: "narrativeminutes",
    polls: "polls",
    procmaterials: "procmaterials",
    recording: "recording",
    review: "review",
    rfc: "rfc",
    shepwrit: "shepwrit",
    slides: "slides",
    statchg: "statchg",
    statement: "statement",
    std: "std"
  }

  MEETING_MATERIAL_TYPES = %w[
    agenda
    bluesheets
    chatlog
    minutes
    narrativeminutes
    polls
    procmaterials
    slides
  ].freeze

  def meeting_material_type?
    document_type.in?(MEETING_MATERIAL_TYPES)
  end

  def material_attached?
    document_material&.file&.attached? || false
  end

  def to_s
    name
  end
end
