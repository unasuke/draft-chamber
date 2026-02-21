# frozen_string_literal: true

class DownloadDocumentMaterialJob < ApplicationJob
  queue_as :download

  THROTTLE_DURATION = 0.5

  discard_on ActiveRecord::RecordNotFound
  discard_on MaterialDownloader::NotFoundError

  def perform(document_id, meeting_number)
    document = Document.find(document_id)

    unless document.meeting_material_type?
      document.document_material&.update!(download_status: :not_downloadable)
      return
    end

    return if document.material_attached?

    material = document.document_material
    return unless material

    material.update!(download_status: :downloading)
    @downloaded = true

    url = Datatracker::Resources::Document
      .new(Datatracker::Client.new)
      .material_url(document.name, meeting_number)

    downloader = MaterialDownloader.new
    result = downloader.download(url)

    material.file.attach(
      io: result[:io],
      filename: result[:filename],
      content_type: result[:content_type]
    )

    material.update!(
      download_status: :completed,
      downloaded_at: Time.current,
      content_type: result[:content_type],
      filename: result[:filename],
      byte_size: result[:io].size
    )

    if material.processable?
      material.update!(processing_status: :processing_pending)
      ProcessDocumentMaterialJob.perform_later(material.id)
    end
  rescue MaterialDownloader::DownloadError => e
    material&.update!(download_status: :failed, download_error: e.message)
    raise
  ensure
    sleep THROTTLE_DURATION if @downloaded
  end
end
