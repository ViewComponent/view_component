# frozen_string_literal: true

module ViewComponent
  module DelegateMissingToMonkeyPatch
    RUBY_RESERVED_KEYWORDS = %w(__ENCODING__ __LINE__ __FILE__ alias and BEGIN begin break
      case class def defined? do else elsif END end ensure false for if in module next nil
      not or redo rescue retry return self super then true undef unless until when while yield)
      DELEGATION_RESERVED_KEYWORDS = %w(_ arg args block)
      DELEGATION_RESERVED_METHOD_NAMES = Set.new(
        RUBY_RESERVED_KEYWORDS + DELEGATION_RESERVED_KEYWORDS
      ).freeze

    def delegate_missing_to(target, allow_nil: nil)
      target = target.to_s
      target = "self.#{target}" if DELEGATION_RESERVED_METHOD_NAMES.include?(target)

      module_eval <<-RUBY, __FILE__, __LINE__ + 1
        def respond_to_missing?(name, include_private = false)
          # It may look like an oversight, but we deliberately do not pass
          # +include_private+, because they do not get delegated.
          return false if name == :marshal_dump || name == :_dump
          #{target}.respond_to?(name) || super
        end
        def method_missing(method, *args, &block)
          if #{target}.respond_to?(method)
            #{target}.public_send(method, *args, &block)
          else
            begin
              super
            rescue NoMethodError
              if #{target}.nil?
                if #{allow_nil == true}
                  nil
                else
                  raise DelegationError, "\#{method} delegated to #{target}, but #{target} is nil"
                end
              else
                raise
              end
            end
          end
        end
        ruby2_keywords(:method_missing) if respond_to?(:ruby2_keywords, true)
      RUBY
    end
  end
end
