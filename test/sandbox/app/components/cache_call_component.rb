# frozen_string_literal: true

class CacheCallComponent < ViewComponent::Base
  include ViewComponent::ExperimentallyCacheable

  cache { [foo] }
  attr_reader :foo

  def initialize(foo:)
    @foo = foo
  end

  def call
    tag.span(foo, class: "cache-call", data: {time: Time.zone.now.to_f})
  end
end
