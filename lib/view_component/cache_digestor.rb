# # frozen_string_literal: true

module ViewComponent
  class CacheDigestor
    @@digest_mutex = Mutex.new

    class << self
      def digest(name:, finder:, format: nil, dependencies: nil)
        if dependencies.nil? || dependencies.empty?
          cache_key = "#{name}.#{format}"
        else
          dependencies_suffix = dependencies.flatten.tap(&:compact!).join(".")
          cache_key = "#{name}.#{format}.#{dependencies_suffix}"
        end
        cache_key
      end
    end
  end
end
