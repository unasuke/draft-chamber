# frozen_string_literal: true

module Datatracker
  # Spaces out requests to datatracker across threads and processes by sharing
  # the next allowed send time through a cache store.
  #
  # Threads in the same process are serialized by a mutex, but the read-then-write
  # on the store is not atomic across processes, so two processes may rarely take
  # the same slot.
  class Throttle
    CACHE_KEY = "datatracker/next_request_at"
    EXPIRES_IN = 3600 # seconds

    def initialize
      @mutex = Mutex.new
    end

    # Reserves the next send slot shared across processes and sleeps until it arrives
    def wait!(interval:, store:, logger: nil)
      now = Time.now.to_f
      slot = @mutex.synchronize do
        reserved = [ now, store.read(CACHE_KEY).to_f ].max
        unless store.write(CACHE_KEY, reserved + interval, expires_in: EXPIRES_IN)
          raise ThrottleError, "Failed to record the next datatracker request slot"
        end
        reserved
      end
      remaining = slot - now
      return unless remaining.positive?

      sleep(remaining)
      logger&.debug("[DatatrackerThrottle] waited #{remaining.round(2)}s")
    end
  end
end
