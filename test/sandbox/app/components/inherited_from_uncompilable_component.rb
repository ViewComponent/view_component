# frozen_string_literal: true

class InheritedFromUncompilableComponent < UncompilableComponent
  def call
    "<div>hello world</div>".html_safe
  end
end
