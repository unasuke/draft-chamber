# frozen_string_literal: true

require "test_helper"

class DatatrackerImport::UriResolverTest < ActiveSupport::TestCase
  test "resolve finds record by resource_uri" do
    result = DatatrackerImport::UriResolver.resolve(
      groups(:tls).resource_uri, Group
    )
    assert_equal groups(:tls), result
  end

  test "resolve returns nil for blank uri" do
    assert_nil DatatrackerImport::UriResolver.resolve(nil, Group)
    assert_nil DatatrackerImport::UriResolver.resolve("", Group)
  end

  test "resolve raises RecordNotFound for unknown uri" do
    assert_raises ActiveRecord::RecordNotFound do
      DatatrackerImport::UriResolver.resolve("/api/v1/group/group/0/", Group)
    end
  end

  test "resolve_optional finds record by resource_uri" do
    result = DatatrackerImport::UriResolver.resolve_optional(
      groups(:tls).resource_uri, Group
    )
    assert_equal groups(:tls), result
  end

  test "resolve_optional returns nil for blank uri" do
    assert_nil DatatrackerImport::UriResolver.resolve_optional(nil, Group)
    assert_nil DatatrackerImport::UriResolver.resolve_optional("", Group)
  end

  test "resolve_optional returns nil for unknown uri" do
    result = DatatrackerImport::UriResolver.resolve_optional(
      "/api/v1/group/group/0/", Group
    )
    assert_nil result
  end
end
