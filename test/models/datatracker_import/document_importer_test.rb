# frozen_string_literal: true

require "test_helper"

class DatatrackerImport::DocumentImporterTest < ActiveSupport::TestCase
  # Stands in for Datatracker::Resources::Document and records each name__in batch
  class FakeDocuments
    attr_reader :batches

    def initialize(objects)
      @objects = objects
      @batches = []
    end

    def find_by_names(names)
      @batches << names
      Struct.new(:objects).new(@objects.select { names.include?(it["name"]) })
    end
  end

  FakeClient = Struct.new(:documents)

  def api_object(name, title: "Slides #{name}")
    {
      "name" => name,
      "title" => title,
      "type" => "slides",
      "abstract" => nil,
      "rev" => "00",
      "pages" => nil,
      "uploaded_filename" => "#{name}.pdf",
      "group" => groups(:tls).resource_uri,
      "time" => "2025-11-01T10:00:00",
      "expires" => nil,
      "resource_uri" => "/api/v1/doc/document/#{name}/"
    }
  end

  test "imports documents by URI" do
    doc_uri = "/api/v1/doc/document/slides-124-new/"
    documents = FakeDocuments.new([ api_object("slides-124-new", title: "New Slides") ])
    importer = DatatrackerImport::DocumentImporter.new(client: FakeClient.new(documents))

    assert_difference "Document.count", 1 do
      stats = importer.import(document_uris: [ doc_uri ])
      assert_equal 1, stats[:created]
    end

    doc = Document.find_by(name: "slides-124-new")
    assert_equal "New Slides", doc.title
    assert_equal "slides", doc.document_type
    assert_equal groups(:tls), doc.group
    assert_equal [ [ "slides-124-new" ] ], documents.batches
  end

  test "fetches documents in batches of 50 names" do
    names = (1..51).map { "slides-124-batch-#{it}" }
    documents = FakeDocuments.new(names.map { api_object(it) })
    importer = DatatrackerImport::DocumentImporter.new(client: FakeClient.new(documents))

    assert_difference "Document.count", 51 do
      importer.import(document_uris: names.map { "/api/v1/doc/document/#{it}/" })
    end

    assert_equal [ 50, 1 ], documents.batches.map(&:size)
  end

  test "fetches and imports a duplicated URI only once" do
    doc_uri = "/api/v1/doc/document/slides-124-dup/"
    documents = FakeDocuments.new([ api_object("slides-124-dup") ])
    importer = DatatrackerImport::DocumentImporter.new(client: FakeClient.new(documents))

    assert_difference "Document.count", 1 do
      stats = importer.import(document_uris: [ doc_uri, doc_uri ])
      assert_equal 1, stats[:created]
      assert_equal 0, stats[:updated]
    end

    assert_equal [ [ "slides-124-dup" ] ], documents.batches
  end

  test "skips already imported documents" do
    existing_uri = documents(:tls_chairs_slides).resource_uri
    fake_documents = FakeDocuments.new([])
    importer = DatatrackerImport::DocumentImporter.new(client: FakeClient.new(fake_documents))

    assert_no_difference "Document.count" do
      stats = importer.import(document_uris: [ existing_uri ])
      assert_equal 0, stats[:created]
    end

    assert_empty fake_documents.batches
  end

  test "counts names the API did not return as errors" do
    documents = FakeDocuments.new([])
    importer = DatatrackerImport::DocumentImporter.new(client: FakeClient.new(documents))

    assert_no_difference "Document.count" do
      stats = importer.import(document_uris: [ "/api/v1/doc/document/nonexistent/" ])
      assert_equal 1, stats[:errors]
    end
  end

  test "lets RateLimitError propagate to the job" do
    documents = Object.new
    def documents.find_by_names(_names)
      raise Datatracker::RateLimitError.new(response: nil)
    end
    importer = DatatrackerImport::DocumentImporter.new(client: FakeClient.new(documents))

    assert_raises(Datatracker::RateLimitError) do
      importer.import(document_uris: [ "/api/v1/doc/document/slides-124-limited/" ])
    end
  end
end
