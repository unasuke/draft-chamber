# frozen_string_literal: true

module Attachable
  extend ActiveSupport::Concern

  ALLOWED_CONTENT_TYPES = %w[
    application/pdf
    text/plain
    text/html
    text/markdown
    application/vnd.openxmlformats-officedocument.presentationml.presentation
    application/vnd.ms-powerpoint
    application/vnd.openxmlformats-officedocument.wordprocessingml.document
    application/json
    video/mp4
    video/webm
    audio/mpeg
    image/png
    image/jpeg
  ].freeze

  MAX_FILE_SIZE = 500.megabytes

  included do
    has_one_attached :file

    validate :file_content_type_is_allowed, if: -> { file.attached? }
    validate :file_size_within_limit, if: -> { file.attached? }
    validate :file_presence, if: :file_required?
  end

  # Override in including model to control when file presence is required
  def file_required?
    true
  end

  private

  def file_presence
    errors.add(:file, "must be attached") unless file.attached?
  end

  def file_content_type_is_allowed
    unless ALLOWED_CONTENT_TYPES.include?(file.content_type)
      errors.add(:file, "has an unsupported content type: #{file.content_type}")
    end
  end

  def file_size_within_limit
    if file.byte_size > MAX_FILE_SIZE
      errors.add(:file, "is too large (max #{MAX_FILE_SIZE / 1.megabyte} MB)")
    end
  end
end
