# frozen_string_literal: true

require "test_helper"

class Datatracker::ThrottleTest < ActiveSupport::TestCase
  # Records sleeps instead of actually sleeping
  class RecordingThrottle < Datatracker::Throttle
    attr_reader :slept

    def initialize
      super
      @slept = []
    end

    private

    def sleep(seconds)
      @slept << seconds
    end
  end

  # Mimics Solid Cache swallowing a transient DB error on write
  class FailingStore
    def initialize(next_at)
      @next_at = next_at
    end

    def read(_key)
      @next_at
    end

    def write(*)
      false
    end
  end

  setup do
    @throttle = RecordingThrottle.new
    @store = ActiveSupport::Cache::MemoryStore.new
    @key = Datatracker::Throttle::CACHE_KEY
  end

  test "does not wait when no slot is recorded and reserves the next one" do
    travel_to Time.zone.local(2026, 11, 11, 12, 0, 0) do
      @throttle.wait!(interval: 2.0, store: @store)

      assert_empty @throttle.slept
      assert_in_delta Time.now.to_f + 2.0, @store.read(@key), 0.001
    end
  end

  test "waits until the reserved slot and reserves the one after it" do
    travel_to Time.zone.local(2026, 11, 11, 12, 0, 0) do
      slot = Time.now.to_f + 1.5
      @store.write(@key, slot)

      @throttle.wait!(interval: 2.0, store: @store)

      assert_equal 1, @throttle.slept.size
      assert_in_delta 1.5, @throttle.slept.first, 0.001
      assert_in_delta slot + 2.0, @store.read(@key), 0.001
    end
  end

  test "does not wait when the recorded slot is in the past" do
    travel_to Time.zone.local(2026, 11, 11, 12, 0, 0) do
      @store.write(@key, Time.now.to_f - 10)

      @throttle.wait!(interval: 2.0, store: @store)

      assert_empty @throttle.slept
      assert_in_delta Time.now.to_f + 2.0, @store.read(@key), 0.001
    end
  end

  test "raises ThrottleError without sleeping when the slot cannot be recorded" do
    travel_to Time.zone.local(2026, 11, 11, 12, 0, 0) do
      store = FailingStore.new(Time.now.to_f + 1.5)

      assert_raises(Datatracker::ThrottleError) do
        @throttle.wait!(interval: 2.0, store: store)
      end
      assert_empty @throttle.slept
    end
  end

  test "logs the wait only when it actually waits" do
    log = StringIO.new
    logger = Logger.new(log)

    travel_to Time.zone.local(2026, 11, 11, 12, 0, 0) do
      @throttle.wait!(interval: 2.0, store: @store, logger: logger)
      assert_empty log.string

      @throttle.wait!(interval: 2.0, store: @store, logger: logger)
      assert_match(/\[DatatrackerThrottle\] waited 2.0s/, log.string)
    end
  end
end
