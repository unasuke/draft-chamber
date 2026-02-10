# frozen_string_literal: true

require "test_helper"

class DatatrackerImport::DocumentImporterTest < ActiveSupport::TestCase
  setup do
    @mock_client = Minitest::Mock.new
    @mock_docs_resource = Minitest::Mock.new
    @importer = DatatrackerImport::DocumentImporter.new(client: @mock_client)
  end

  test "imports documents by URI" do
    doc_uri = "/api/v1/doc/document/slides-124-new/"
    api_object = {
      "name" => "slides-124-new",
      "title" => "New Slides",
      "type" => "slides",
      "abstract" => nil,
      "rev" => "00",
      "pages" => nil,
      "uploaded_filename" => "slides-124-new.pdf",
      "group" => groups(:tls).resource_uri,
      "time" => "2025-11-01T10:00:00",
      "expires" => nil,
      "resource_uri" => doc_uri
    }

    mock_response = Minitest::Mock.new
    mock_response.expect(:objects, [ api_object ])
    @mock_client.expect(:documents, @mock_docs_resource)
    @mock_docs_resource.expect(:find_by_name, mock_response) { true }

    assert_difference "Document.count", 1 do
      stats = @importer.import(document_uris: [ doc_uri ])
      assert_equal 1, stats[:created]
    end

    doc = Document.find_by(name: "slides-124-new")
    assert_equal "New Slides", doc.title
    assert_equal "slides", doc.document_type
    assert_equal groups(:tls), doc.group
  end

  test "skips already imported documents" do
    existing_uri = documents(:tls_chairs_slides).resource_uri

    assert_no_difference "Document.count" do
      stats = @importer.import(document_uris: [ existing_uri ])
      assert_equal 0, stats[:created]
    end
  end

  test "handles NotFoundError gracefully" do
    doc_uri = "/api/v1/doc/document/nonexistent/"

    @mock_client.expect(:documents, @mock_docs_resource)
    @mock_docs_resource.expect(:find_by_name, nil) do
      raise Datatracker::NotFoundError.new(response: nil)
    end

    assert_no_difference "Document.count" do
      stats = @importer.import(document_uris: [ doc_uri ])
      assert_equal 1, stats[:errors]
    end
  end
end
