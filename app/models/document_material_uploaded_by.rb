# frozen_string_literal: true

class DocumentMaterialUploadedBy < ApplicationRecord
  belongs_to :document_material
  belongs_to :user
end
