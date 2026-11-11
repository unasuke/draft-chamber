# frozen_string_literal: true

require "test_helper"

class Datatracker::Resources::DocumentTest < ActiveSupport::TestCase
  test "find_by_names requests the names as a comma-separated name__in filter" do
    response = Struct.new(:status, :body).new(200, { "meta" => {}, "objects" => [] })
    client = Minitest::Mock.new
    client.expect(:get, response, [
      "/api/v1/doc/document/",
      { name__in: "rfc9000,rfc9001", limit: 2 }
    ])

    result = Datatracker::Resources::Document.new(client).find_by_names(%w[rfc9000 rfc9001])

    assert_equal [], result.objects
    client.verify
  end
end
