# frozen_string_literal: true

class FormComponent < ViewComponent::Base
  with_content_areas :header, :body, :footer

  def post
    @post ||= Post.new(title: "Check It Out")
  end
end
