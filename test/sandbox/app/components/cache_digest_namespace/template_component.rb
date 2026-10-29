# frozen_string_literal: true

module CacheDigestNamespace
  class TemplateComponent < ViewComponent::Base
    Child = ChildComponent
    ErbComponent = Module.new

    erb_template "<%= render Child.new %>"
  end
end
