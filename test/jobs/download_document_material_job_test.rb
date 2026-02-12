# frozen_string_literal: true

require "test_helper"

class DownloadDocumentMaterialJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @document = documents(:tls_chairs_slides)
    @meeting_number = "124"
  end

  test "downloads and attaches material to document" do
    material = @document.create_document_material!(download_status: :pending)

    mock_result = {
      io: StringIO.new("test PDF content"),
      filename: "slides-124-tls-chairs.pdf",
      content_type: "application/pdf"
    }

    mock_downloader = Minitest::Mock.new
    mock_downloader.expect(:download, mock_result, [ String ])

    MaterialDownloader.stub(:new, mock_downloader) do
      DownloadDocumentMaterialJob.perform_now(@document.id, @meeting_number)
    end

    assert @document.reload.material_attached?
    material.reload
    assert_equal "completed", material.download_status
    assert_equal "slides-124-tls-chairs.pdf", material.filename
    assert_equal "application/pdf", material.content_type
    assert_not_nil material.downloaded_at
    assert_equal "processing_pending", material.processing_status
    mock_downloader.verify
  end

  test "enqueues ProcessDocumentMaterialJob for processable content types" do
    material = @document.create_document_material!(download_status: :pending)

    mock_result = {
      io: StringIO.new("test PDF content"),
      filename: "slides-124-tls-chairs.pdf",
      content_type: "application/pdf"
    }

    mock_downloader = Minitest::Mock.new
    mock_downloader.expect(:download, mock_result, [ String ])

    MaterialDownloader.stub(:new, mock_downloader) do
      assert_enqueued_with(job: ProcessDocumentMaterialJob) do
        DownloadDocumentMaterialJob.perform_now(@document.id, @meeting_number)
      end
    end
  end

  test "does not enqueue ProcessDocumentMaterialJob for text content" do
    material = @document.create_document_material!(download_status: :pending)

    mock_result = {
      io: StringIO.new("plain text content"),
      filename: "slides.txt",
      content_type: "text/plain"
    }

    mock_downloader = Minitest::Mock.new
    mock_downloader.expect(:download, mock_result, [ String ])

    MaterialDownloader.stub(:new, mock_downloader) do
      assert_no_enqueued_jobs(only: ProcessDocumentMaterialJob) do
        DownloadDocumentMaterialJob.perform_now(@document.id, @meeting_number)
      end
    end

    assert_equal "not_applicable", material.reload.processing_status
  end

  test "skips if material already attached" do
    material = @document.create_document_material!(download_status: :pending)
    material.file.attach(
      io: StringIO.new("existing content"),
      filename: "existing.pdf",
      content_type: "application/pdf"
    )
    material.update!(download_status: :completed)

    # No MaterialDownloader should be created
    DownloadDocumentMaterialJob.perform_now(@document.id, @meeting_number)

    assert_equal "completed", material.reload.download_status
  end

  test "skips if no document material record exists" do
    # No material record exists, job should return early
    DownloadDocumentMaterialJob.perform_now(@document.id, @meeting_number)
    assert_nil @document.reload.document_material
  end

  test "marks material as failed on download error" do
    material = @document.create_document_material!(download_status: :pending)

    failing_downloader = Object.new
    def failing_downloader.download(_url)
      raise MaterialDownloader::DownloadError, "HTTP 404"
    end

    assert_raises(MaterialDownloader::DownloadError) do
      MaterialDownloader.stub(:new, failing_downloader) do
        DownloadDocumentMaterialJob.perform_now(@document.id, @meeting_number)
      end
    end

    material.reload
    assert_equal "failed", material.download_status
    assert_equal "HTTP 404", material.download_error
  end

  test "discards job when document not found" do
    assert_nothing_raised do
      DownloadDocumentMaterialJob.perform_now(-1, @meeting_number)
    end
  end
end
