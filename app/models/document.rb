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
    slides: "slides",
    draft: "draft",
    agenda: "agenda",
    minutes: "minutes"
  }

  def material_attached?
    document_material&.file&.attached? || false
  end

  def to_s
    name
  end
end
