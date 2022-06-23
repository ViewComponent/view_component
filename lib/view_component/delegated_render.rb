# frozen_string_literal: true

module ViewComponent
  module DelegatedRender
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def delegate_render_to(target)
        module_eval <<~RUBY
          def call
            #{target}.render_in(view_context) { content }
          end
        RUBY
      end
    end
  end
end
