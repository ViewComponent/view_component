# frozen_string_literal: true

require "view_component/compile_cache_lock"

module ViewComponent
  # Keeps track of which templates have already been compiled
  # This isn't part of the public API
  module CompileCache
    mattr_accessor :cache, instance_reader: false, instance_accessor: false do
      Set.new
    end

    mattr_accessor :lock, instance_reader: false, instance_accessor: false do
      ViewComponent::Lock.new
    end

    module_function

    def register(klass)
      cache << klass
    end

    def compiled?(klass)
      cache.include? klass
    end

    def invalidate_class!(klass)
      cache.delete(klass)
    end

    def invalidate!
      lock.with_write_lock { cache.clear }
    end

    def with_read_lock(&block)
      lock.with_read_lock(&block)
    end
  end
end
