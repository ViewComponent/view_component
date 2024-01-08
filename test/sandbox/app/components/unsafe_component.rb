# frozen_string_literal: true

class UnsafeComponent < ViewComponent::Base
  def call
    user_input = "<script>alert('hello!')</script>"

    "<div>hello #{user_input}</div>"
  end
end
