module ViewComponent
  class ViewContextCalledBeforeRenderError < StandardError; end

  class ControllerCalledBeforeRenderError < StandardError
    MESSAGE =
      "`#controller` can't be used during initialization, as it depends " \
      "on the view context that only exists once a ViewComponent is passed to " \
      "the Rails render pipeline.\n\n" \
      "It's sometimes possible to fix this issue by moving code dependent on " \
      "`#controller` to a `#before_render` method: https://viewcomponent.org/api.html#before_render--void."

    def initialize
      super(MESSAGE)
    end
  end
end
