# frozen_string_literal: true

class InheritedFromUncompilableComponent < UncompilableComponent
  def call
    "<div>hello world</div>"
  end
end
