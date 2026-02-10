# frozen_string_literal: true

class Document < ApplicationRecord
  belongs_to :group, optional: true
  has_one :document_material, dependent: :destroy
  has_many :session_presentations, dependent: :destroy
  has_many :sessions, through: :session_presentations

  validates :name, presence: true, uniqueness: true
  validates :resource_uri, presence: true, uniqueness: true

  enum :document_type, {
    slides: "slides",
    draft: "draft",
    agenda: "agenda",
    minutes: "minutes"
  }

  def material_attached?
    document_material&.file&.attached? || false
  end
end
