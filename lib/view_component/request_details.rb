# frozen_string_literal: true

module ViewComponent
  # LookupContext computes and encapsulates @details for each request
  # so that it doesn't need to be recomputed on each partial render.
  # This data is wrapped in ActionView::TemplateDetails::Requested and
  # used by instances of ActionView::Resolver to choose which template
  # best matches the request.
  #
  # ActionView considers this logic internal to template/partial resolution.
  # We're exposing it to the compiler via `refine` so that ViewComponent
  # can match Rails' template picking logic.
  module RequestDetails
    EMPTY_DETAILS = {}.freeze

    refine ActionView::LookupContext do
      # Return an abstraction for matching and sorting available templates
      # based on the current lookup context details.
      #
      # @return ActionView::TemplateDetails::Requested
      # @see ActionView::LookupContext#detail_args_for
      # @see ActionView::FileSystemResolver#_find_all
      def vc_requested_details(user_details = EMPTY_DETAILS)
        # The hash `user_details` would normally be the standard arguments that
        # `render` accepts, but there's currently no mechanism for users to
        # provide these when calling render on a ViewComponent.
        if user_details.equal?(EMPTY_DETAILS)
          # Fast path: memoize the empty-details Requested per LookupContext.
          # Rendered many times with the same context, the tuple/Requested
          # allocations from ActionView are then paid at most once.
          cached = instance_variable_defined?(:@__vc_requested_details_cache) &&
            @__vc_requested_details_cache
          return cached if cached

          details, from_cache = detail_args_for(EMPTY_DETAILS)
          @__vc_requested_details_cache =
            from_cache || ActionView::TemplateDetails::Requested.new(**details)
        else
          details, from_cache = detail_args_for(user_details)
          from_cache || ActionView::TemplateDetails::Requested.new(**details)
        end
      end
    end
  end
end
