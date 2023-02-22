# frozen_string_literal: true

require "test_helper"

class InlineErbTest < ViewComponent::TestCase
  class InlineErbComponent < ViewComponent::Base
    include ViewComponent::InlineTemplate

    attr_reader :name

    erb_template <<~ERB
      <h1>Hello, <%= name %>!</h1>
    ERB

    def initialize(name)
      @name = name
    end
  end

  class InlineRaiseErbComponent < ViewComponent::Base
    include ViewComponent::InlineTemplate

    attr_reader :name

    erb_template <<~ERB
      <h1>Hello, <%= raise ArgumentError, "oh no" %>!</h1>
    ERB

    def initialize(name)
      @name = name
    end
  end

  class InlineErbSubclassComponent < InlineErbComponent
    erb_template <<~ERB
      <h1>Hey, <%= name %>!</h1>
    ERB
  end

  class InlineSlimComponent < ViewComponent::Base
    include ViewComponent::InlineTemplate

    attr_reader :name

    slim_template <<~SLIM
      h1
        | Hello,
        = " " + name
        | !
    SLIM

    def initialize(name)
      @name = name
    end
  end

  class InheritedInlineSlimComponent < InlineSlimComponent
  end

  class SlotsInlineComponent < ViewComponent::Base
    include ViewComponent::InlineTemplate

    renders_one :greeting, InlineErbComponent

    erb_template <<~ERB
      <div class="greeting-container">
        <%= greeting %>
      </div>
    ERB
  end

  test "renders inline templates" do
    render_inline(InlineErbComponent.new("Fox Mulder"))

    assert_selector("h1", text: "Hello, Fox Mulder!")
  end

  test "error backtrace locations work" do
    error = assert_raises ArgumentError do
      render_inline(InlineRaiseErbComponent.new("Fox Mulder"))
    end

    assert_match %r{test/sandbox/test/inline_template_test.rb:26}, error.backtrace[0]
  end

  test "renders inline slim templates" do
    render_inline(InlineSlimComponent.new("Fox Mulder"))

    assert_selector("h1", text: "Hello, Fox Mulder!")
  end

  test "inherits template_language" do
    assert_equal "slim", InheritedInlineSlimComponent.inline_template_language
  end

  test "subclassed erb works" do
    render_inline(InlineErbSubclassComponent.new("Fox Mulder"))

    assert_selector("h1", text: "Hey, Fox Mulder!")
  end

  test "calling template methods multiple times raises an exception" do
    error = assert_raises ViewComponent::ComponentError do
      Class.new(InlineErbComponent) do
        erb_template "foo"
        erb_template "bar"
      end
    end

    assert_equal "inline templates can only be defined once per-component", error.message
  end

  test "calling template methods with more or less than 1 argument raises" do
    assert_raises ArgumentError do
      Class.new(InlineErbComponent) do
        erb_template
      end
    end

    assert_raises ArgumentError do
      Class.new(InlineErbComponent) do
        erb_template "omg", "wow"
      end
    end
  end

  test "works with slots" do
    render_inline SlotsInlineComponent.new do |c|
      c.with_greeting("Fox Mulder")
    end

    assert_selector(".greeting-container h1", text: "Hello, Fox Mulder!")
  end
end
