# frozen_string_literal: true

class TableContentsComponent < ViewComponent::Base
  def call
    "<td>td contents</td>".html_safe
  end
end
