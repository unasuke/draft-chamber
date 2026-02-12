# frozen_string_literal: true

class ConvertedDocumentMaterial < ApplicationRecord
  belongs_to :document_material

  has_one_attached :file

  scope :ordered, -> { order(:page_number) }
end
