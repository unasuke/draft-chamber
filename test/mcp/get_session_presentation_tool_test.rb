# frozen_string_literal: true

require "test_helper"

class GetSessionPresentationToolTest < ActiveSupport::TestCase
  test "returns presentation with document details and material URL" do
    response = GetSessionPresentationTool.call(
      server_context: {}, document_name: "slides-124-tls-chairs"
    )
    result = JSON.parse(response.content.first[:text])
    presentation = result.first

    assert_equal 1, presentation["order"]
    assert_equal "01", presentation["rev"]
    assert_equal "slides-124-tls-chairs", presentation["document"]["name"]
    assert_equal "TLS Chairs Slides", presentation["document"]["title"]
    assert_equal "slides", presentation["document"]["type"]
    assert_includes presentation["material_url"], "datatracker.ietf.org"
    assert_includes presentation["material_url"], "124"
    assert_includes presentation["material_url"], "slides-124-tls-chairs"
    assert_equal false, presentation["document"]["file_available"]
    assert_nil presentation["document"]["file_download_status"]
  end

  test "includes session and meeting information" do
    response = GetSessionPresentationTool.call(
      server_context: {}, document_name: "slides-124-tls-chairs"
    )
    result = JSON.parse(response.content.first[:text])
    session = result.first["session"]

    assert_equal 34365, session["id"]
    assert_equal "tls", session["group"]
    assert_equal "124", session["meeting_number"]
  end

  test "returns error for non-existent document" do
    response = GetSessionPresentationTool.call(
      server_context: {}, document_name: "nonexistent-doc"
    )

    assert response.error?
    assert_includes response.content.first[:text], "Document"
  end

  test "returns error when document has no presentations" do
    response = GetSessionPresentationTool.call(
      server_context: {}, document_name: "slides-124-plenary"
    )

    assert response.error?
    assert_includes response.content.first[:text], "No presentation found"
  end
end
