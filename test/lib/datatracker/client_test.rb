# frozen_string_literal: true

require "test_helper"

class Datatracker::ClientTest < ActiveSupport::TestCase
  test "sets the configured User-Agent on its connection" do
    client = Datatracker::Client.new

    assert_equal Datatracker.configuration.user_agent, client.connection.headers["User-Agent"]
  end

  test "default User-Agent identifies the app with a contact point" do
    assert_match %r{\Adraft-chamber \(\+https://}, Datatracker::Configuration.new.user_agent
  end

  test "honors a custom configured User-Agent" do
    config = Datatracker::Configuration.new
    config.user_agent = "custom-agent/1.0"

    assert_equal "custom-agent/1.0", Datatracker::Client.new(config).connection.headers["User-Agent"]
  end
end
