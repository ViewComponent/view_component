# frozen_string_literal: true

require "test_helper"

class InlineErbTest < ViewComponent::TestCase
  class InlineErbComponent < ViewComponent::Base
    attr_reader :name

    erb_template <<~ERB
      <h1>Hello, <%= name %>!</h1>
    ERB

    def initialize(name)
      @name = name
    end
  end

  class InlineRaiseErbComponent < ViewComponent::Base
    attr_reader :name

    erb_template <<~ERB
      <h1>Hello, <%= raise ArgumentError, "oh no" %>!</h1>
    ERB

    def initialize(name)
      @name = name
    end
  end

  class InlineRaiseSlimComponent < ViewComponent::Base
    attr_reader :name

    slim_template <<~SLIM
      = raise ArgumentError, "oh no"
    SLIM

    def initialize(name)
      @name = name
    end
  end

  class InlineErbSubclassComponent < InlineErbComponent
    erb_template <<~ERB
      <h1>Hey, <%= name %>!</h1>
      <div class="parent">
        <%= render_parent %>
      </div>
    ERB
  end

  class InlineSlimComponent < ViewComponent::Base
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
    renders_one :greeting, InlineErbComponent

    erb_template <<~ERB
      <div class="greeting-container">
        <%= greeting %>
      </div>
    ERB
  end

  class ParentBaseComponent < ViewComponent::Base
  end

  class InlineErbChildComponent < ParentBaseComponent
    attr_reader :name

    erb_template <<~ERB
      <h1>Hello, <%= name %>!</h1>
    ERB

    def initialize(name)
      @name = name
    end
  end

  class InlineComponentDerivedFromComponentSupportingVariants < Level2Component
    erb_template <<~ERB
      <div class="inline-template">
        <%= render_parent %>
      </div>
    ERB
  end

  test "renders inline templates" do
    render_inline(InlineErbComponent.new("Fox Mulder"))

    assert_selector("h1", text: "Hello, Fox Mulder!")
  end

  test "renders inline templates when inheriting base component" do
    render_inline(InlineErbChildComponent.new("Fox Mulder"))

    assert_selector("h1", text: "Hello, Fox Mulder!")
  end

  test "error backtrace locations work" do
    error = assert_raises ArgumentError do
      render_inline(InlineRaiseErbComponent.new("Fox Mulder"))
    end

    assert_match %r{test/sandbox/test/inline_template_test.rb:22}, error.backtrace[0]
  end

  test "error backtrace locations work in slim" do
    error = assert_raises ArgumentError do
      render_inline(InlineRaiseSlimComponent.new("Fox Mulder"))
    end

    assert_match %r{test/sandbox/test/inline_template_test.rb:34}, error.backtrace[0]
  end

  test "renders inline slim templates" do
    render_inline(InlineSlimComponent.new("Fox Mulder"))

    assert_selector("h1", text: "Hello, Fox Mulder!")
  end

  test "inherits template_language" do
    assert_equal "slim", InheritedInlineSlimComponent.__vc_inline_template_language
  end

  test "subclassed erb works" do
    render_inline(InlineErbSubclassComponent.new("Fox Mulder"))

    assert_selector("h1", text: "Hey, Fox Mulder!")
  end

  test "child components can render their parent" do
    render_inline(InlineErbSubclassComponent.new("Fox Mulder"))

    assert_selector(".parent h1", text: "Hello, Fox Mulder!")
  end

  test "inline child component propagates variant to parent" do
    with_variant :variant do
      render_inline(InlineComponentDerivedFromComponentSupportingVariants.new)
    end

    assert_selector ".inline-template .level2-component.variant .level1-component"
  end

  test "calling template methods multiple times raises an exception" do
    error = assert_raises ViewComponent::MultipleInlineTemplatesError do
      Class.new(InlineErbComponent) do
        erb_template "foo"
        erb_template "bar"
      end
    end

    assert_equal "Inline templates can only be defined once per-component.", error.message
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

  # Regression test for https://github.com/ViewComponent/view_component/issues/2540
  # Negative lineno values in class_eval cause segfaults when Ruby's Coverage module
  # is enabled. This test verifies that components can be compiled and rendered when
  # coverage is running.
  test "file-based templates compile without segfault when coverage is running" do
    skip unless Rails::VERSION::MAJOR >= 8 && Rails::VERSION::MINOR > 0

    with_new_cache do
      with_coverage_running do
        # Force recompilation with coverage "enabled"
        ViewComponent::CompileCache.cache.delete(ErbComponent)

        # This would segfault before the fix due to negative lineno
        render_inline(ErbComponent.new(message: "Foo bar"))

        assert_selector("div", text: "Foo bar")
      end
    end
  end

  # Regression test for segfault when coverage is running but annotations are DISABLED.
  # This is the common case in CI environments.
  test "file-based templates compile without segfault when coverage is running and annotations disabled" do
    skip unless Rails::VERSION::MAJOR >= 8 && Rails::VERSION::MINOR > 0

    without_template_annotations do
      with_coverage_running do
        # Force recompilation with coverage "enabled" but annotations disabled
        ViewComponent::CompileCache.cache.delete(ErbComponent)

        # This would segfault in v4.3.0 because it only avoided -1 lineno
        # when annotations were enabled
        render_inline(ErbComponent.new(message: "Foo bar"))

        assert_selector("div", text: "Foo bar")
      end
    end
  end

  test "inline templates compile without segfault when coverage is running" do
    skip unless Rails::VERSION::MAJOR >= 8 && Rails::VERSION::MINOR > 0

    with_new_cache do
      with_coverage_running do
        # Force recompilation with coverage "enabled"
        ViewComponent::CompileCache.cache.delete(InlineRaiseErbComponent)

        # Inline templates should still work (lineno is 2+, so -1 won't be negative)
        error = assert_raises ArgumentError do
          render_inline(InlineRaiseErbComponent.new("Fox Mulder"))
        end

        # Verify backtrace still points to correct line
        assert_match %r{test/sandbox/test/inline_template_test.rb:22}, error.backtrace[0]
      end
    end
  end

  private

  def with_coverage_running
    require "coverage"
    already_running = Coverage.running?
    Coverage.start unless already_running
    yield
  ensure
    Coverage.result unless already_running
  end
end
