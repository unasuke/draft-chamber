# frozen_string_literal: true

require "test_helper"

class MaterialDownloaderTest < ActiveSupport::TestCase
  test "downloads file and returns io, filename, content_type" do
    stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.get("/meeting/124/materials/slides-124-tls-chairs/") do
        [
          200,
          {
            "content-type" => "application/pdf",
            "content-disposition" => 'attachment; filename="slides-124-tls-chairs.pdf"'
          },
          "PDF content"
        ]
      end
    end
    conn = Faraday.new("https://datatracker.ietf.org") { |f| f.adapter :test, stubs }
    downloader = MaterialDownloader.new(connection: conn)

    result = downloader.download("https://datatracker.ietf.org/meeting/124/materials/slides-124-tls-chairs/")

    assert_equal "slides-124-tls-chairs.pdf", result[:filename]
    assert_equal "application/pdf", result[:content_type]
    assert_equal "PDF content", result[:io].read
    stubs.verify_stubbed_calls
  end

  test "follows redirects" do
    stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.get("/meeting/124/materials/slides-124-tls-chairs/") do
        [ 302, { "location" => "https://datatracker.ietf.org/final-url/slides.pdf" }, "" ]
      end
      stub.get("/final-url/slides.pdf") do
        [ 200, { "content-type" => "application/pdf" }, "PDF content" ]
      end
    end
    conn = Faraday.new("https://datatracker.ietf.org") { |f| f.adapter :test, stubs }
    downloader = MaterialDownloader.new(connection: conn)

    result = downloader.download("https://datatracker.ietf.org/meeting/124/materials/slides-124-tls-chairs/")

    assert_equal "application/pdf", result[:content_type]
    assert_equal "PDF content", result[:io].read
    stubs.verify_stubbed_calls
  end

  test "raises DownloadError on HTTP error" do
    stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.get("/meeting/124/materials/nonexistent/") do
        [ 404, {}, "Not Found" ]
      end
    end
    conn = Faraday.new("https://datatracker.ietf.org") { |f| f.adapter :test, stubs }
    downloader = MaterialDownloader.new(connection: conn)

    assert_raises(MaterialDownloader::DownloadError) do
      downloader.download("https://datatracker.ietf.org/meeting/124/materials/nonexistent/")
    end
    stubs.verify_stubbed_calls
  end

  test "raises DownloadError on too many redirects" do
    stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      7.times do |i|
        stub.get("/redirect/#{i}") do
          [ 302, { "location" => "https://datatracker.ietf.org/redirect/#{i + 1}" }, "" ]
        end
      end
    end
    conn = Faraday.new("https://datatracker.ietf.org") { |f| f.adapter :test, stubs }
    downloader = MaterialDownloader.new(connection: conn)

    assert_raises(MaterialDownloader::DownloadError) do
      downloader.download("https://datatracker.ietf.org/redirect/0")
    end
  end

  test "infers filename from URL path when content-disposition is absent" do
    stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.get("/meeting/124/materials/slides-124-tls-chairs/") do
        [ 200, { "content-type" => "application/pdf" }, "content" ]
      end
    end
    conn = Faraday.new("https://datatracker.ietf.org") { |f| f.adapter :test, stubs }
    downloader = MaterialDownloader.new(connection: conn)

    result = downloader.download("https://datatracker.ietf.org/meeting/124/materials/slides-124-tls-chairs/")

    assert_equal "slides-124-tls-chairs.pdf", result[:filename]
    stubs.verify_stubbed_calls
  end

  test "adds extension from content-type when filename has no extension" do
    stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.get("/file/document") do
        [ 200, { "content-type" => "text/html; charset=utf-8" }, "<html></html>" ]
      end
    end
    conn = Faraday.new("https://example.com") { |f| f.adapter :test, stubs }
    downloader = MaterialDownloader.new(connection: conn)

    result = downloader.download("https://example.com/file/document")

    assert_equal "document.html", result[:filename]
    assert_equal "text/html", result[:content_type]
    stubs.verify_stubbed_calls
  end
end
