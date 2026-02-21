# frozen_string_literal: true

require "test_helper"

class DocumentTest < ActiveSupport::TestCase
  test "valid document" do
    doc = Document.new(name: "slides-124-test", document_type: "slides",
                       resource_uri: "/api/v1/doc/document/slides-124-test/")
    assert doc.valid?
  end

  test "requires name" do
    doc = Document.new(resource_uri: "/api/v1/doc/document/test/")
    assert_not doc.valid?
    assert_includes doc.errors[:name], "can't be blank"
  end

  test "requires resource_uri" do
    doc = Document.new(name: "test-doc")
    assert_not doc.valid?
    assert_includes doc.errors[:resource_uri], "can't be blank"
  end

  test "name must be unique" do
    doc = Document.new(name: documents(:tls_chairs_slides).name,
                       resource_uri: "/api/v1/doc/document/dup/")
    assert_not doc.valid?
    assert_includes doc.errors[:name], "has already been taken"
  end

  test "group is optional" do
    assert_nil documents(:ungrouped_doc).group
    assert documents(:ungrouped_doc).valid?
  end

  test "belongs_to group" do
    assert_equal groups(:tls), documents(:tls_chairs_slides).group
  end

  test "has_many sessions through session_presentations" do
    assert_includes documents(:tls_chairs_slides).sessions, sessions(:tls_at_124)
  end

  test "slides scope" do
    slides = Document.slides
    assert_includes slides, documents(:tls_chairs_slides)
    assert_not_includes slides, documents(:tls_draft)
  end

  test "draft scope" do
    drafts = Document.draft
    assert_includes drafts, documents(:tls_draft)
    assert_not_includes drafts, documents(:tls_chairs_slides)
  end

  test "agenda scope" do
    agendas = Document.agenda
    assert_includes agendas, documents(:tls_agenda)
    assert_not_includes agendas, documents(:tls_chairs_slides)
  end

  test "minutes scope" do
    minutes = Document.minutes
    assert_includes minutes, documents(:tls_minutes)
    assert_not_includes minutes, documents(:tls_chairs_slides)
  end

  test "meeting_material_type? returns true for meeting material types" do
    Document::MEETING_MATERIAL_TYPES.each do |type|
      doc = Document.new(name: "#{type}-124-test", document_type: type,
                         resource_uri: "/api/v1/doc/document/#{type}-124-test/")
      assert doc.meeting_material_type?, "Expected #{type} to be a meeting material type"
    end
  end

  test "meeting_material_type? returns false for non-meeting material types" do
    %w[draft rfc recording bcp bofreq charter conflrev fyi liaison review shepwrit statchg statement std].each do |type|
      doc = Document.new(name: "#{type}-124-test", document_type: type,
                         resource_uri: "/api/v1/doc/document/#{type}-124-test/")
      assert_not doc.meeting_material_type?, "Expected #{type} not to be a meeting material type"
    end
  end
end
