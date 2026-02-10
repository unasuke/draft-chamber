#!/usr/bin/env ruby
# frozen_string_literal: true

require "net/http"
require "json"
require "uri"
require "fileutils"

# Configuration
IETF_MEETING = 124
IETF_WG = "tls"
BASE_URL = "https://datatracker.ietf.org"
DOWNLOAD_MATERIAL = true
DOWNLOAD_DIR = "tmp/materials"

def fetch_session_presentations(meeting, wg)
  uri = URI("#{BASE_URL}/api/v1/meeting/sessionpresentation/")
  uri.query = URI.encode_www_form(
    "session__meeting__number" => meeting,
    "session__group__acronym" => wg,
    "limit" => 0
  )

  response = Net::HTTP.get_response(uri)

  unless response.is_a?(Net::HTTPSuccess)
    raise "API request failed: #{response.code} #{response.message}"
  end

  JSON.parse(response.body)
end

def extract_document_name(document_uri)
  document_uri.split("/").last
end

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

def extension_from_content_type(content_type)
  return nil unless content_type

  mime_type = content_type.split(";").first&.strip
  CONTENT_TYPE_TO_EXT[mime_type]
end

def download_file(file_url, download_dir)
  uri = URI(file_url)
  filename = nil

  Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
    request = Net::HTTP::Get.new(uri)
    http.request(request) do |response|
      case response
      when Net::HTTPRedirection
        return download_file(response["location"], download_dir)
      when Net::HTTPSuccess
        content_disposition = response["content-disposition"]
        if content_disposition && content_disposition =~ /filename="?([^"]+)"?/
          filename = $1
        else
          filename = File.basename(uri.path)
        end

        if File.extname(filename).empty?
          ext = extension_from_content_type(response["content-type"])
          filename = "#{filename}#{ext}" if ext
        end

        filepath = File.join(download_dir, filename)
        File.open(filepath, "wb") do |file|
          response.read_body do |chunk|
            file.write(chunk)
          end
        end
        return filepath
      else
        warn "Failed to download #{file_url}: #{response.code} #{response.message}"
        return nil
      end
    end
  end
end

def main
  data = fetch_session_presentations(IETF_MEETING, IETF_WG)

  if DOWNLOAD_MATERIAL
    FileUtils.mkdir_p(DOWNLOAD_DIR)
  end

  presentations = data["objects"].map do |obj|
    document_name = extract_document_name(obj["document"])
    file_url = "#{BASE_URL}/meeting/#{IETF_MEETING}/materials/#{document_name}/"

    presentation = {
      id: obj["id"],
      document: document_name,
      url: "#{BASE_URL}/doc/#{document_name}/",
      file_url: file_url,
      session: obj["session"],
      order: obj["order"],
      rev: obj["rev"]
    }

    if DOWNLOAD_MATERIAL
      puts "Downloading #{document_name}..."
      filepath = download_file(file_url, DOWNLOAD_DIR)
      presentation[:downloaded_path] = filepath if filepath
    end

    presentation
  end

  result = {
    meeting: IETF_MEETING,
    wg: IETF_WG,
    total_count: data["meta"]["total_count"],
    presentations: presentations
  }

  puts JSON.pretty_generate(result)
end

main
