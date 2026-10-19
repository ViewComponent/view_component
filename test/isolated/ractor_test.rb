# frozen_string_literal: true

require "bundler/setup"
require "minitest/autorun"
require "tmpdir"
require "rails"
require "action_controller/railtie"
require "active_support/testing/isolation"
require "view_component"

# Boots a production application, calls the experimental
# `Rails.application.ractorize!`, and renders components in non-main Ractors.
# Requires Ruby 4.0+ and a Rails/Rack version that supports `ractorize!`.
# Skips elsewhere, except in the rails_main_head CI job (Ruby head, pinned
# Rails, Rack, and i18n), where every prerequisite is expected to be met.
class RactorTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::Isolation

  COMPONENTS = {
    "app/components/greeting_component.rb" => <<~RUBY,
      class GreetingComponent < ViewComponent::Base
        def initialize(name:) = @name = name
        def before_render = @name = @name.upcase
      end
    RUBY
    "app/components/greeting_component.html.erb" => "<div>Hello <%= @name %><%= content %></div>",
    "app/components/inline_component.rb" => <<~RUBY,
      class InlineComponent < ViewComponent::Base
        def call = content_tag(:p, "inline")
      end
    RUBY
    "app/components/variant_component.rb" => "class VariantComponent < ViewComponent::Base; end",
    "app/components/variant_component.html.erb" => "default",
    "app/components/variant_component.html+phone.erb" => "phone",
    "app/components/parent_component.rb" => "class ParentComponent < ViewComponent::Base; end",
    "app/components/parent_component.html.erb" => "<b>parent</b>",
    "app/components/child_component.rb" => <<~RUBY,
      class ChildComponent < ParentComponent
        def call = "<i>\#{render_parent_to_string}</i>".html_safe
      end
    RUBY
    "app/components/slots_component.rb" => <<~RUBY,
      class SlotsComponent < ViewComponent::Base
        renders_one :header, ->(title:) { content_tag(:h1, title) }
        renders_many :items, "ItemComponent"
      end
    RUBY
    "app/components/slots_component.html.erb" => "<%= header %><ul><% items.each do |i| %><%= i %><% end %></ul>",
    "app/components/item_component.rb" => <<~RUBY,
      class ItemComponent < ViewComponent::Base
        with_collection_parameter :item
        def initialize(item:, item_counter: nil) = (@item = item; @counter = item_counter)
        def call = content_tag(:li, "\#{@item}\#{@counter}")
      end
    RUBY
    "app/components/translated_component.rb" => <<~RUBY,
      class TranslatedComponent < ViewComponent::Base
        def call = t(".hello")
      end
    RUBY
    "app/components/translated_component.en.yml" => "en:\n  hello: Hi from sidecar\n",
    # Wrapper components instead of ActionView templates: Rails compiles views
    # lazily in each Ractor, which recent Ruby head builds don't allow.
    "app/components/slots_page_component.rb" => <<~RUBY,
      class SlotsPageComponent < ViewComponent::Base
        def call
          render(SlotsComponent.new) do |c|
            c.with_header(title: "T")
            c.with_item(item: "a")
            c.with_item(item: "b")
            nil
          end
        end
      end
    RUBY
    "app/components/collection_page_component.rb" => <<~RUBY,
      class CollectionPageComponent < ViewComponent::Base
        def call = render(ItemComponent.with_collection(%w[x y]))
      end
    RUBY
    "app/components/content_page_component.rb" => <<~RUBY,
      class ContentPageComponent < ViewComponent::Base
        def call = render(GreetingComponent.new(name: "blk")) { "!" }
      end
    RUBY
    "app/controllers/greetings_controller.rb" => <<~RUBY,
      class GreetingsController < ActionController::Base
        def plain = render(plain: "ok")
        def show = render(GreetingComponent.new(name: "Ractor"))
        def inline = render(InlineComponent.new)
        def child = render(ChildComponent.new)
        def translated = render(TranslatedComponent.new)
        def slots = render(SlotsPageComponent.new)
        def collection = render(CollectionPageComponent.new)
        def content = render(ContentPageComponent.new)

        def variant
          request.variant = params[:v]&.to_sym
          render(VariantComponent.new)
        end
      end
    RUBY
    "config/routes.rb" => <<~RUBY
      Rails.application.routes.draw do
        %w[plain show inline variant child translated slots collection content].each do |action|
          get "/\#{action}", to: "greetings#\#{action}"
        end
      end
    RUBY
  }.freeze

  def setup
    skip_unless_required "Ractor rendering requires Ruby 4.0+" if RUBY_VERSION < "4.0"
    skip_unless_required "Rails.application.ractorize! is unavailable" unless Rails::Application.method_defined?(:ractorize!)

    begin
      require "rack/ractorize"
      require "active_support/ractors"
    rescue LoadError
      skip_unless_required "rack/ractorize is unavailable"
    end
  end

  def test_components_render_in_non_main_ractors
    boot_ractorized_app

    status, body = request("/plain")
    skip_unless_required "Rails can't render in a non-main Ractor in this environment: #{body}" unless status == 200

    {
      "/show" => "<div>Hello RACTOR</div>",
      "/inline" => "<p>inline</p>",
      "/variant" => "default",
      "/variant?v=phone" => "phone",
      "/child" => "<i><b>parent</b></i>",
      "/slots" => "<h1>T</h1><ul><li>a</li><li>b</li></ul>",
      "/collection" => "<li>x0</li><li>y1</li>",
      "/content" => "<div>Hello BLK!</div>"
    }.each do |path, expected|
      assert_equal [200, expected], request(path), path
    end
  end

  def test_translations_render_in_non_main_ractors
    boot_ractorized_app

    # Requires an i18n release with Ractor support (ruby-i18n/i18n#741).
    status, body = request("/translated")
    skip_unless_required "i18n can't translate in a non-main Ractor: #{body}" if status != 200 && body.include?("I18n")

    assert_equal [200, "Hi from sidecar"], [status, body]
  end

  private

  def skip_unless_required(message)
    (ENV["RAILS_VERSION"] == "main_head") ? flunk(message) : skip(message)
  end

  def boot_ractorized_app
    root = Dir.mktmpdir
    COMPONENTS.each do |path, source|
      FileUtils.mkdir_p(File.dirname(File.join(root, path)))
      File.write(File.join(root, path), source)
    end

    Rails.env = "production"
    # Some Rails framework callbacks aren't shareable yet; warn rather than fail on them.
    ActiveSupport::Ractors.unshareable_proc_action = :warn
    app = Class.new(Rails::Application) do
      config.root = root
      config.eager_load = true
      config.enable_reloading = false
      config.secret_key_base = "x" * 64
      config.logger = ActiveSupport::Ractors::Logger.new
      config.public_file_server.enabled = false
      config.cache_store = :null_store
      config.hosts.clear
      config.action_dispatch.show_exceptions = :none
      config.view_component.previews.enabled = false
    end
    app.initialize!
    app.ractorize!
    # Rails leaves some frozen Sets unshareable, such as `action_methods`, the
    # Mime registry, and renderers. Reading them from a non-main Ractor crashes
    # Ruby head instead of raising an IsolationError, so share them up front,
    # skipping ViewComponent's own state.
    AbstractController::Base.descendants.each(&:action_methods)
    ObjectSpace.each_object(Module) do |mod|
      next if mod.name&.start_with?("ViewComponent") || mod <= ViewComponent::Base

      mod.instance_variables.each do |ivar|
        value = mod.instance_variable_get(ivar)
        Ractor.make_shareable(value) if value.frozen? && !Ractor.shareable?(value)
      rescue Ractor::Error, TypeError
        nil
      end
    end
  end

  def request(path)
    env = Rack::MockRequest.env_for(path)
    env.delete("rack.input")
    env.delete("rack.errors")

    Ractor.new(env) do |env|
      env["rack.errors"] = $stderr
      status, _headers, body = Rails.application.call(env)
      out = +""
      body.each { out << _1 }
      body.close if body.respond_to?(:close)
      [status, out.strip]
    rescue Exception => e # standard:disable Lint/RescueException
      e = e.cause while e.cause
      [e.class.name, "#{e.class}: #{e.message} #{e.backtrace&.first(3)&.join(" ")}"]
    end.value
  end
end
