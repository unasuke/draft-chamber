# frozen_string_literal: true

class MaterialDownloader
  CONTENT_TYPE_TO_EXT = {
    "application/pdf" => ".pdf",
    "text/plain" => ".txt",
    "text/html" => ".html",
    "text/markdown" => ".md",
    "application/vnd.openxmlformats-officedocument.presentationml.presentation" => ".pptx",
    "application/vnd.ms-powerpoint" => ".ppt",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document" => ".docx",
    "video/mp4" => ".mp4",
    "video/webm" => ".webm",
    "audio/mpeg" => ".mp3",
    "image/png" => ".png",
    "image/jpeg" => ".jpg"
  }.freeze

  MAX_REDIRECTS = 5

  class DownloadError < StandardError; end
  class NotFoundError < DownloadError; end

  attr_reader :connection

  def initialize(connection: nil)
    @connection = connection || build_connection
  end

  # Downloads material and returns a hash with :io, :filename, :content_type
  def download(url)
    response = follow_redirects(url)

    content_type = extract_content_type(response)
    filename = extract_filename(response, url, content_type)

    {
      io: StringIO.new(response.body),
      filename: filename,
      content_type: content_type
    }
  end

  private

  def build_connection
    Faraday.new do |faraday|
      faraday.request :retry, max: 2, interval: 0.5, backoff_factor: 2
      faraday.options.timeout = 120
      faraday.options.open_timeout = 15
      faraday.adapter Faraday.default_adapter
    end
  end

  def follow_redirects(url, redirect_count = 0)
    raise DownloadError, "Too many redirects" if redirect_count > MAX_REDIRECTS

    response = connection.get(url)

    if (300..399).cover?(response.status) && response.headers["location"]
      follow_redirects(response.headers["location"], redirect_count + 1)
    elsif (200..299).cover?(response.status)
      response
    elsif response.status == 404
      raise NotFoundError, "Download failed: HTTP 404"
    else
      raise DownloadError, "Download failed: HTTP #{response.status}"
    end
  end

  def extract_content_type(response)
    raw = response.headers["content-type"]
    return "application/octet-stream" unless raw

    raw.split(";").first&.strip || "application/octet-stream"
  end

  def extract_filename(response, url, content_type)
    disposition = response.headers["content-disposition"]
    if disposition && disposition =~ /filename="?([^";\s]+)"?/
      return $1
    end

    uri = URI.parse(url)
    basename = File.basename(uri.path.chomp("/"))

    if File.extname(basename).empty?
      ext = CONTENT_TYPE_TO_EXT[content_type]
      basename = "#{basename}#{ext}" if ext
    end

    basename
  end
end
