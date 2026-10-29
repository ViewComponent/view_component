# frozen_string_literal: true

require "test_helper"
require "view_component/configurable"

class ViewComponent::Base::UnitTest < Minitest::Test
  def test_identifier
    assert(MyComponent.identifier.include?("test/sandbox/app/components/my_component.rb"))
  end

  def skip_templates_parses_all_types_of_paths
    file_path = [
      "/Users/fake.user/path/to.templates/component/test_component.html+phone.erb",
      "/_underscore-dash./component/test_component.html+desktop.slim",
      "/tilda~/component/test_component.html.haml"
    ]
    expected = [
      {variant: :phone, handler: "erb"},
      {variant: :desktop, handler: "slim"},
      {variant: nil, handler: "haml"}
    ]

    compiler = ViewComponent::Compiler.new(ViewComponent::Base)

    ViewComponent::Base.stub(:sidecar_files, file_path) do
      templates = compiler.send(:gather_templates)

      templates.each_with_index do |template, index|
        assert_equal(template[:path], file_path[index])
        if expected[index][:variant].nil?
          # Minitest requires using #assert_nil if asserting nil!
          assert_nil(template[:variant])
        else
          assert_equal(template[:variant], expected[index][:variant])
        end
        assert_equal(template[:handler], expected[index][:handler])
      end
    end
  end

  def test_calling_helpers_outside_render_raises
    component = ViewComponent::Base.new
    err =
      assert_raises ViewComponent::HelpersCalledBeforeRenderError do
        component.helpers
      end
    assert_includes err.message, "can't be used before rendering"
  end

  def test_calling_controller_outside_render_raises
    component = ViewComponent::Base.new
    err =
      assert_raises ViewComponent::ControllerCalledBeforeRenderError do
        component.controller
      end

    assert_includes err.message, "can't be used before rendering"
  end

  def test_sidecar_files
    root = ViewComponent::Engine.root.join("test/sandbox")

    assert_equal(
      [
        "#{root}/app/components/template_and_sidecar_directory_template_component.html.erb",
        "#{root}/app/components/template_and_sidecar_directory_template_component/" \
        "template_and_sidecar_directory_template_component.html.erb"
      ],
      TemplateAndSidecarDirectoryTemplateComponent.sidecar_files(["erb"])
    )

    assert_equal(
      [
        "#{root}/app/components/css_sidecar_file_component.css",
        "#{root}/app/components/css_sidecar_file_component.html.erb"
      ],
      CssSidecarFileComponent.sidecar_files(["css", "erb"])
    )

    assert_equal(
      ["#{root}/app/components/css_sidecar_file_component.css"],
      CssSidecarFileComponent.sidecar_files(["css"])
    )

    assert_equal(
      ["#{root}/app/components/translatable_component.yml"],
      TranslatableComponent.sidecar_files(["yml"])
    )
  end

  def test_sidecar_files_are_looked_up_once_while_eager_loading
    Dir.mktmpdir do |directory|
      component = Class.new(ViewComponent::Base)
      component.identifier = File.join(directory, "temporary_component.rb")
      component.define_singleton_method(:name) { "TemporaryComponent" }
      template = File.join(directory, "temporary_component.html.erb")

      ViewComponent::CompileCache.with_sidecar_files_cache do
        assert_empty component.__vc_sidecar_files(["erb"])

        File.write(template, "<div></div>")
        assert_empty component.__vc_sidecar_files(["erb"])
        assert_empty component.sidecar_files(["erb"])
      end

      assert_equal [template], component.__vc_sidecar_files(["erb"])
    end
  end

  def test_cached_sidecar_directory_listings_preserve_file_discovery
    components = [
      TemplateAndSidecarDirectoryTemplateComponent,
      CssSidecarFileComponent,
      TranslatableComponent,
      SlotsComponent::MyHighlightComponent
    ]
    extensions = %w[erb css yml]
    expected = components.map { |component| component.sidecar_files(extensions) }

    ViewComponent::CompileCache.with_sidecar_files_cache do
      assert_equal expected, components.map { |component| component.__vc_sidecar_files(extensions) }
    end
  end

  def test_sidecar_directory_listings_are_shared_across_components_and_extensions
    Dir.mktmpdir do |directory|
      paths = %w[first_component.html.erb first_component.yml second_component.html+phone.erb].map do |name|
        File.join(directory, name).tap { |path| File.write(path, "") }
      end
      scans = 0
      glob = Dir.method(:glob)

      scan = lambda do |*args|
        scans += 1
        glob.call(*args)
      end

      Dir.stub(:glob, scan) do
        ViewComponent::CompileCache.with_sidecar_files_cache do
          assert_equal paths.first(2).sort, ViewComponent::CompileCache.sidecar_files_matching("#{directory}/first_component.*")
          assert_equal [paths.last], ViewComponent::CompileCache.sidecar_files_matching("#{directory}/second_component.*")
          assert_equal 1, scans
        end
      end
    end
  end

  def test_sidecar_directory_listings_are_discarded_after_an_error
    Dir.mktmpdir do |directory|
      pattern = "#{directory}/temporary_component.*"
      assert_raises(RuntimeError) do
        ViewComponent::CompileCache.with_sidecar_files_cache do
          assert_empty ViewComponent::CompileCache.sidecar_files_matching(pattern)
          raise "compilation failed"
        end
      end

      template = File.join(directory, "temporary_component.html.erb")
      File.write(template, "")
      assert_equal [template], ViewComponent::CompileCache.sidecar_files_matching(pattern)
      ViewComponent::CompileCache.with_sidecar_files_cache do
        assert_equal [template], ViewComponent::CompileCache.sidecar_files_matching(pattern)
      end
    end
  end

  def test_cached_sidecar_directory_listings_preserve_glob_matching
    Dir.mktmpdir do |directory|
      %w[example.html.erb example.part.html.erb example_other.html.erb .example.html.erb].each do |name|
        File.write(File.join(directory, name), "")
      end
      patterns = %w[example.* example.part.* example_other.* .example.* example{,_other}.* missing.* subdirectory/example.*]
        .map { |name| File.join(directory, name) }
      expected = patterns.map { |pattern| Dir[pattern] }

      ViewComponent::CompileCache.with_sidecar_files_cache do
        assert_equal expected, patterns.map { |pattern| ViewComponent::CompileCache.sidecar_files_matching(pattern) }
      end
    end
  end

  def test_source_file_contents_are_shared_only_while_eager_loading
    Dir.mktmpdir do |directory|
      path = File.join(directory, "temporary_component.html.erb")
      File.write(path, "original")

      ViewComponent::CompileCache.with_sidecar_files_cache do
        ViewComponent::CompileCache.read_file(path).replace("modified by a template handler")
        File.write(path, "edited")

        assert_equal "original", ViewComponent::CompileCache.read_file(path)
      end

      assert_equal "edited", ViewComponent::CompileCache.read_file(path)
      File.write(path, "edited again")
      assert_equal "edited again", ViewComponent::CompileCache.read_file(path)

      ViewComponent::CompileCache.with_sidecar_files_cache do
        assert_equal "edited again", ViewComponent::CompileCache.read_file(path)
      end
    end
  end

  def test_source_file_contents_are_discarded_after_an_error
    Dir.mktmpdir do |directory|
      path = File.join(directory, "temporary_component.html.erb")
      File.write(path, "original")

      assert_raises(RuntimeError) do
        ViewComponent::CompileCache.with_sidecar_files_cache do
          assert_equal "original", ViewComponent::CompileCache.read_file(path)
          raise "compilation failed"
        end
      end

      File.write(path, "edited")
      assert_equal "edited", ViewComponent::CompileCache.read_file(path)
    end
  end

  def test_template_path_parser_is_shared_only_while_eager_loading
    parser = nil
    ViewComponent::CompileCache.with_sidecar_files_cache do
      parser = ViewComponent::CompileCache.path_parser
      assert_same parser, ViewComponent::CompileCache.path_parser
      details = parser.parse("example.en.html+phone.erb").details
      assert_equal [:en, :html, :phone, :erb], [details.locale, details.format, details.variant, details.handler]
    end

    refute_same parser, ViewComponent::CompileCache.path_parser
    refute_same ViewComponent::CompileCache.path_parser, ViewComponent::CompileCache.path_parser
  end

  def test_template_path_parser_is_discarded_after_an_error
    parser = nil
    assert_raises(RuntimeError) do
      ViewComponent::CompileCache.with_sidecar_files_cache do
        parser = ViewComponent::CompileCache.path_parser
        raise "compilation failed"
      end
    end

    refute_same parser, ViewComponent::CompileCache.path_parser
  end

  def test_compiled_status_tracks_cache_invalidation
    MyComponent.__vc_compile
    assert_predicate MyComponent, :__vc_compiled?

    ViewComponent::CompileCache.invalidate_class!(MyComponent)
    refute_predicate MyComponent, :__vc_compiled?

    MyComponent.__vc_compile
    assert_predicate MyComponent, :__vc_compiled?
  end

  def test_default_output_preamble_and_postamble
    component = MyComponent.new
    [component.output_preamble, component.output_postamble].each do |output|
      assert_empty output
      assert_predicate output, :html_safe?
      assert_predicate output, :frozen?
    end
  end

  def test_html_safe_output_does_not_need_a_blankness_check
    output = "<p>safe</p>".html_safe
    output.stub(:blank?, -> { flunk "HTML-safe output should not be scanned for whitespace" }) do
      assert_same output, MyComponent.new.send(:__vc_maybe_escape_html, output) { flunk "HTML-safe output should not warn" }
    end
  end

  def test_does_not_render_additional_newline_with_render_in
    without_template_annotations do
      ActionView::Template::Handlers::ERB.strip_trailing_newlines = true
      rendered_output = Array.new(2) {
        DisplayInlineComponent.new.render_in(ActionController::Base.new.view_context)
      }.join
      assert_includes rendered_output, "<span>Hello, world!</span><span>Hello, world!</span>"
    end
  ensure
    ActionView::Template::Handlers::ERB.strip_trailing_newlines = false
  end

  def test_render_looks_up_the_overridden_virtual_path_once
    component = MyComponent.new
    view_context = ActionController::Base.new.view_context
    view_context.instance_variable_set(:@virtual_path, "original")
    lookups = 0
    paths = nil
    component.define_singleton_method(:virtual_path) do
      lookups += 1
      "custom/component"
    end
    component.define_singleton_method(:before_render) do
      paths = [@virtual_path, @view_context.instance_variable_get(:@virtual_path)]
    end

    component.render_in(view_context)

    assert_equal 1, lookups
    assert_equal ["custom/component", "custom/component"], paths
    assert_equal "original", view_context.instance_variable_get(:@virtual_path)
  end

  def test_evaled_component
    source = <<~RUBY
      class EvaledComponent < ViewComponent::Base
        def initialize(cta: nil, title:)
          @cta = cta
          @title = title
        end
        private

        attr_reader :cta, :title
      end
    RUBY

    eval(source) # rubocop:disable Security/Eval
  end

  def test_no_method_error_does_not_reference_helper_if_view_context_not_present
    exception = assert_raises(NoMethodError) { Class.new(ViewComponent::Base).new.current_user }
    exception_message_regex = Regexp.new <<~MESSAGE.chomp, Regexp::MULTILINE
      undefined method `current_user' for .*

      You may be trying to call a method provided as a view helper. Did you mean `helpers.current_user`?
    MESSAGE
    assert !exception_message_regex.match?(exception.message)
  end

  def test_no_method_error_references_helper_if_view_context_present
    view_context = ActionController::Base.new.view_context
    view_context.instance_eval {
      def current_user
        "a user"
      end
    }
    exception = assert_raises(NameError) { ReferencesMethodOnHelpersComponent.new.render_in(view_context) }
    exception_advice = "You may be trying to call a method provided as a view helper. Did you mean `helpers.current_user`?"
    assert exception.message.include?(exception_advice)
  end

  def test_no_method_error_does_not_reference_missing_helper
    view_context = ActionController::Base.new.view_context
    exception = assert_raises(NameError) { ReferencesMethodOnHelpersComponent.new.render_in(view_context) }
    exception_message_regex = Regexp.new <<~MESSAGE.chomp
      You may be trying to call a method provided as a view helper\\. Did you mean `helpers.current_user`\\?$
    MESSAGE
    assert !exception_message_regex.match?(exception.message)
  end

  module TestModuleWithoutConfig
    class SomeComponent < ViewComponent::Base
    end
  end

  # Config defined on top-level module as opposed to engine.
  module TestModuleWithConfig
    include ViewComponent::Configurable

    configure do |config|
      config.view_component.instrumentation_enabled = false
    end

    class SomeComponent < ViewComponent::Base
    end
  end

  module TestAlreadyConfigurableModule
    include ViewComponent::Configurable

    configure do |config|
      config.view_component.instrumentation_enabled = false
    end

    class SomeComponent < ViewComponent::Base
    end
  end

  module TestAlreadyConfiguredModule
    include ViewComponent::Configurable

    configure do |config|
      config.view_component = ActiveSupport::InheritableOptions[instrumentation_enabled: false]
    end

    class SomeComponent < ViewComponent::Base
    end
  end

  def test_uses_module_configuration
    assert_equal true, TestModuleWithoutConfig::SomeComponent.instrumentation_enabled
    assert_equal false, TestModuleWithConfig::SomeComponent.instrumentation_enabled
    assert_equal false, TestAlreadyConfigurableModule::SomeComponent.instrumentation_enabled
    assert_equal false, TestAlreadyConfiguredModule::SomeComponent.instrumentation_enabled
  end

  def test_after_compile_hook_called_on_compile
    klass = Class.new(ViewComponent::Base) do
      @@calls = 0

      def self.calls
        @@calls
      end

      class << self
        def after_compile
          @@calls += 1
        end
      end

      erb_template ""
    end

    self.class.const_set(:TempHookComponent, klass)
    ViewComponent::CompileCache.invalidate_class!(klass)

    ViewComponent::Compiler.new(klass).compile(force: true)
    assert_equal 1, klass.calls
  ensure
    self.class.send(:remove_const, :TempHookComponent) if self.class.const_defined?(:TempHookComponent)
    ViewComponent::CompileCache.invalidate_class!(klass) if defined?(klass)
  end

  def test_after_compile_not_called_on_cached_compile
    klass = Class.new(ViewComponent::Base) do
      @@calls = 0

      def self.calls
        @@calls
      end

      class << self
        def after_compile
          @@calls += 1
        end
      end

      erb_template ""
    end

    self.class.const_set(:TempHookCachedComponent, klass)
    ViewComponent::CompileCache.invalidate_class!(klass)

    compiler = ViewComponent::Compiler.new(klass)
    compiler.compile(force: true)
    assert_equal 1, klass.calls

    # compile again without force -> should not call hook again
    compiler.compile
    assert_equal 1, klass.calls
  ensure
    self.class.send(:remove_const, :TempHookCachedComponent) if self.class.const_defined?(:TempHookCachedComponent)
    ViewComponent::CompileCache.invalidate_class!(klass) if defined?(klass)
  end
end
