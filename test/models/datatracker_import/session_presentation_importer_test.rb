# frozen_string_literal: true

require "test_helper"

class DatatrackerImport::SessionPresentationImporterTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @mock_client = Minitest::Mock.new
    @mock_sp_resource = Minitest::Mock.new
    @mock_docs_resource = Minitest::Mock.new
    @importer = DatatrackerImport::SessionPresentationImporter.new(client: @mock_client)
  end

  test "imports session presentations and their documents" do
    doc_uri = "/api/v1/doc/document/slides-124-tls-newslides/"
    session_uri = sessions(:tls_at_124).resource_uri

    sp_objects = [
      {
        "session" => session_uri,
        "document" => doc_uri,
        "order" => 5,
        "rev" => "00",
        "resource_uri" => "/api/v1/meeting/sessionpresentation/60000/"
      }
    ]

    doc_api_object = {
      "name" => "slides-124-tls-newslides",
      "title" => "New TLS Slides",
      "type" => "slides",
      "abstract" => nil,
      "rev" => "00",
      "pages" => nil,
      "uploaded_filename" => nil,
      "group" => groups(:tls).resource_uri,
      "time" => "2025-11-01T10:00:00",
      "expires" => nil,
      "resource_uri" => doc_uri
    }

    # SessionPresentation API call
    @mock_client.expect(:session_presentations, @mock_sp_resource)
    mock_sp_response = Minitest::Mock.new
    mock_sp_response.expect(:objects, sp_objects)
    mock_sp_response.expect(:next_page?, false)
    @mock_sp_resource.expect(:list, mock_sp_response) { true }

    # Document API call (from DocumentImporter)
    @mock_client.expect(:documents, @mock_docs_resource)
    mock_doc_response = Minitest::Mock.new
    mock_doc_response.expect(:objects, [ doc_api_object ])
    @mock_docs_resource.expect(:find_by_name, mock_doc_response) { true }

    assert_difference "SessionPresentation.count", 1 do
      assert_difference "Document.count", 1 do
        assert_enqueued_with(job: DownloadDocumentMaterialJob) do
          stats = @importer.import(meeting_number: "124")
          assert_equal 1, stats[:created]
        end
      end
    end

    sp = SessionPresentation.find_by(resource_uri: "/api/v1/meeting/sessionpresentation/60000/")
    assert_equal sessions(:tls_at_124), sp.session
    assert_equal 5, sp.order
    assert_equal "slides-124-tls-newslides", sp.document.name

    # DocumentMaterial record should have been created
    assert_not_nil sp.document.document_material
    assert_equal "pending", sp.document.document_material.download_status
  end

  test "skips presentation when session not found" do
    sp_objects = [
      {
        "session" => "/api/v1/meeting/session/0/",
        "document" => documents(:tls_chairs_slides).resource_uri,
        "order" => 0,
        "rev" => "00",
        "resource_uri" => "/api/v1/meeting/sessionpresentation/60001/"
      }
    ]

    @mock_client.expect(:session_presentations, @mock_sp_resource)
    mock_sp_response = Minitest::Mock.new
    mock_sp_response.expect(:objects, sp_objects)
    mock_sp_response.expect(:next_page?, false)
    @mock_sp_resource.expect(:list, mock_sp_response) { true }

    assert_no_difference "SessionPresentation.count" do
      stats = @importer.import(meeting_number: "124")
      assert_equal 1, stats[:errors]
    end
  end
end
