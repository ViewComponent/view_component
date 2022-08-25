# frozen_string_literal: true

require "concurrent-ruby"

module ViewComponent
  class Lock
    RUNNING_WRITER = 1 << 29

    def initialize
      @counter = Concurrent::AtomicFixnum.new
      @lock = Concurrent::Synchronization::Lock.new
    end

    def with_read_lock
      acquire_read_lock
      begin
        yield
      ensure
        release_read_lock
      end
    end

    def with_write_lock
      acquire_write_lock
      begin
        yield
      ensure
        release_write_lock
      end
    end

    def acquire_read_lock
      while true
        @lock.wait_until { !has_writer }
        break if add_reader
      end
    end

    def release_read_lock
      while true
        if remove_reader
          @lock.broadcast unless read_write_locked
          break
        end
      end

      true
    end

    def acquire_write_lock
      while true
        @lock.wait_until { !read_write_locked }
        break if lock_for_writing
      end
    end

    def release_write_lock
      false until unlock_from_writing
      @lock.broadcast

      true
    end

    private

    def read_write_locked
      @counter.value != 0
    end

    def has_writer
      @counter.value >= RUNNING_WRITER
    end

    def add_reader
      current_value = @counter.value
      @counter.compare_and_set(current_value, current_value + 1)
    end

    def remove_reader
      current_value = @counter.value
      @counter.compare_and_set(current_value, current_value - 1)
    end

    def lock_for_writing
      @counter.compare_and_set(0, 0 + RUNNING_WRITER)
    end

    def unlock_from_writing
      @counter.compare_and_set(RUNNING_WRITER, 0)
    end
  end
end
