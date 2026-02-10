# frozen_string_literal: true

require "test_helper"

class SessionPresentationTest < ActiveSupport::TestCase
  test "valid session_presentation" do
    sp = SessionPresentation.new(
      session: sessions(:quic_at_124),
      document: documents(:ungrouped_doc),
      order: 0,
      resource_uri: "/api/v1/meeting/sessionpresentation/99999/"
    )
    assert sp.valid?
  end

  test "requires session" do
    sp = SessionPresentation.new(
      document: documents(:ungrouped_doc),
      resource_uri: "/api/v1/meeting/sessionpresentation/99998/"
    )
    assert_not sp.valid?
    assert_includes sp.errors[:session], "must exist"
  end

  test "requires document" do
    sp = SessionPresentation.new(
      session: sessions(:tls_at_124),
      resource_uri: "/api/v1/meeting/sessionpresentation/99997/"
    )
    assert_not sp.valid?
    assert_includes sp.errors[:document], "must exist"
  end

  test "requires resource_uri" do
    sp = SessionPresentation.new(
      session: sessions(:tls_at_124),
      document: documents(:ungrouped_doc)
    )
    assert_not sp.valid?
    assert_includes sp.errors[:resource_uri], "can't be blank"
  end

  test "session_id and document_id must be unique together" do
    existing = session_presentations(:tls_chairs_at_124)
    sp = SessionPresentation.new(
      session: existing.session,
      document: existing.document,
      resource_uri: "/api/v1/meeting/sessionpresentation/99996/"
    )
    assert_not sp.valid?
    assert_includes sp.errors[:session_id], "has already been taken"
  end

  test "ordered scope sorts by order" do
    ordered = sessions(:tls_at_124).session_presentations.ordered
    orders = ordered.map(&:order)
    assert_equal orders.sort, orders
  end

  test "belongs_to session" do
    assert_equal sessions(:tls_at_124),
                 session_presentations(:tls_chairs_at_124).session
  end

  test "belongs_to document" do
    assert_equal documents(:tls_chairs_slides),
                 session_presentations(:tls_chairs_at_124).document
  end
end
