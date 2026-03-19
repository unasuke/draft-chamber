# frozen_string_literal: true

require "test_helper"

class Datatracker::Resources::BaseTest < ActiveSupport::TestCase
  setup do
    @client = Minitest::Mock.new
    @resource = Class.new(Datatracker::Resources::Base) {
      def endpoint
        "/api/v1/test/"
      end
    }.new(@client)
  end

  test "raises ForbiddenError on 403 response" do
    response = Struct.new(:status, :headers, :body, keyword_init: true)
      .new(status: 403, headers: { "retry-after" => "60" }, body: { "error" => "rate limited" })

    assert_raises(Datatracker::ForbiddenError) do
      @resource.send(:handle_response, response)
    end
  end
end
