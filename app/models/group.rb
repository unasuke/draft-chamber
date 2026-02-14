# frozen_string_literal: true

class Group < ApplicationRecord
  belongs_to :parent, class_name: "Group", optional: true
  has_many :children, class_name: "Group", foreign_key: :parent_id,
           inverse_of: :parent, dependent: :nullify
  has_many :sessions, dependent: :destroy
  has_many :documents, dependent: :nullify
  has_many :stale_reports, as: :reportable, dependent: :destroy

  validates :acronym, presence: true, uniqueness: true
  validates :resource_uri, presence: true, uniqueness: true

  scope :active, -> { where(state: "active") }
  scope :working_groups, -> { where(group_type: "wg") }

  def to_param
    acronym
  end

  def to_s
    acronym
  end
end
