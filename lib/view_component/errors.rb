module ViewComponent
  class BaseError < StandardError
    def initialize
      super(self.class::MESSAGE)
    end
  end

  class ReservedPluralSlotNameError < StandardError
    MESSAGE =
      "COMPONENT_CLASS_NAME declares a slot named SLOT_NAME, which is a reserved word in the ViewComponent framework.\n\n" \
      "To fix this issue, choose a different name."

    def initialize(klass_name, slot_name)
      super(MESSAGE.gsub("COMPONENT_CLASS_NAME", klass_name.to_s).gsub("SLOT_NAME", slot_name.to_s))
    end
  end

  class NilWithContentError < BaseError
    MESSAGE =
      "No content provided to `#with_content` for #{self}.\n\n" \
      "To fix this issue, pass a value."
  end

  class TranslateCalledBeforeRenderError < BaseError
    MESSAGE =
      "`#translate` can't be used during initialization as it depends " \
      "on the view context that only exists once a ViewComponent is passed to " \
      "the Rails render pipeline.\n\n" \
      "It's sometimes possible to fix this issue by moving code dependent on " \
      "`#translate` to a `#before_render` method: https://viewcomponent.org/api.html#before_render--void."
  end

  class HelpersCalledBeforeRenderError < BaseError
    MESSAGE =
      "`#helpers` can't be used during initialization as it depends " \
      "on the view context that only exists once a ViewComponent is passed to " \
      "the Rails render pipeline.\n\n" \
      "It's sometimes possible to fix this issue by moving code dependent on " \
      "`#helpers` to a `#before_render` method: https://viewcomponent.org/api.html#before_render--void."
  end

  class ControllerCalledBeforeRenderError < BaseError
    MESSAGE =
      "`#controller` can't be used during initialization, as it depends " \
      "on the view context that only exists once a ViewComponent is passed to " \
      "the Rails render pipeline.\n\n" \
      "It's sometimes possible to fix this issue by moving code dependent on " \
      "`#controller` to a [`#before_render` method](https://viewcomponent.org/api.html#before_render--void)."
  end
end
