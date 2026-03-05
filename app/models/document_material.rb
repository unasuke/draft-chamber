# frozen_string_literal: true

class DocumentMaterial < ApplicationRecord
  include Attachable

  PDF_CONTENT_TYPE = "application/pdf"
  PPTX_CONTENT_TYPE = "application/vnd.openxmlformats-officedocument.presentationml.presentation"
  PPT_CONTENT_TYPE = "application/vnd.ms-powerpoint"
  TEXT_CONTENT_TYPES = %w[text/plain text/html text/markdown].freeze
  PROCESSABLE_CONTENT_TYPES = [ PDF_CONTENT_TYPE, PPTX_CONTENT_TYPE, PPT_CONTENT_TYPE ].freeze

  belongs_to :document

  has_many :converted_document_materials, dependent: :destroy
  has_many :document_material_uploaded_bys, dependent: :destroy

  enum :download_status, {
    pending: "pending",
    downloading: "downloading",
    completed: "completed",
    failed: "failed",
    not_downloadable: "not_downloadable"
  }

  enum :processing_status, {
    not_applicable: "not_applicable",
    processing_pending: "processing_pending",
    processing: "processing",
    processing_completed: "processing_completed",
    processing_failed: "processing_failed"
  }

  validates :document_id, uniqueness: true

  def file_required?
    completed?
  end

  def pdf?
    content_type == PDF_CONTENT_TYPE
  end

  def presentation?
    content_type.in?([ PPTX_CONTENT_TYPE, PPT_CONTENT_TYPE ])
  end

  def text?
    content_type.in?(TEXT_CONTENT_TYPES)
  end

  def processable?
    content_type.in?(PROCESSABLE_CONTENT_TYPES)
  end

  def slide_document?
    document.slides?
  end
end
