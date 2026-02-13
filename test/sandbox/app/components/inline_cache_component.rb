# frozen_string_literal: true

class InlineCacheComponent < ViewComponent::Base
  include ViewComponent::ExperimentallyCacheable

  cache_on :foo, :bar

  attr_reader :foo, :bar

  def initialize(foo:, bar:)
    @foo = foo
    @bar = bar
  end

  erb_template <<~ERB
    <p class='cache-component__cache-key'><%= view_cache_dependencies %></p>
    <p class='cache-component__cache-message' data-time=data-time="<%= Time.zone.now %>"><%= "\#{foo} \#{bar}" %></p>

    <%= render(ButtonToComponent.new) %>
  ERB
end
