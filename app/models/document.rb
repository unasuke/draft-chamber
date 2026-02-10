# frozen_string_literal: true

class Document < ApplicationRecord
  belongs_to :group, optional: true
  has_many :session_presentations, dependent: :destroy
  has_many :sessions, through: :session_presentations

  validates :name, presence: true, uniqueness: true
  validates :resource_uri, presence: true, uniqueness: true

  scope :slides, -> { where(document_type: "slides") }
  scope :drafts, -> { where(document_type: "draft") }
  scope :agendas, -> { where(document_type: "agenda") }
  scope :minutes, -> { where(document_type: "minutes") }
end
