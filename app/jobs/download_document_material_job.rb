# frozen_string_literal: true

class DownloadDocumentMaterialJob < ApplicationJob
  queue_as :default

  discard_on ActiveRecord::RecordNotFound

  def perform(document_id, meeting_number)
    document = Document.find(document_id)
    return if document.material_attached?

    material = document.document_material
    return unless material

    material.update!(download_status: :downloading)

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
  rescue MaterialDownloader::DownloadError => e
    material&.update!(download_status: :failed, download_error: e.message)
    raise
  end
end
