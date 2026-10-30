# frozen_string_literal: true

require "generators/view_component/abstract_generator"

module ViewComponent
  module Generators
    class ComponentGenerator < Rails::Generators::NamedBase
      include ViewComponent::AbstractGenerator

      source_root File.expand_path("templates", __dir__)

      argument :attributes, type: :array, default: [], banner: "attribute"

      class_option :call, type: :boolean, default: false
      class_option :inline, type: :boolean, default: false
      class_option :locale, type: :boolean, default: ViewComponent::Base.config.generate.locale
      class_option :parent, type: :string, desc: "The parent class for the generated component"
      class_option :preview, type: :boolean, default: ViewComponent::Base.config.generate.preview
      class_option :sidecar, type: :boolean
      class_option :stimulus, type: :boolean
      class_option :typescript, type: :boolean

      def check_class_collision
        class_collisions component_class_name
      end

      def create_component_file
        template "component.rb", File.join(component_path, class_path, "#{destination_file_name}.rb")
      end

      hook_for :test_framework

      hook_for :preview, type: :boolean

      hook_for :stimulus, type: :boolean

      hook_for :locale, type: :boolean

      hook_for :template_engine do |instance, template_engine|
        instance.invoke template_engine, [instance.name]
      end

      private

      def parent_class
        return options[:parent] if options[:parent]

        ViewComponent::Base.config.generate.parent_class || default_parent_class
      end

      def initialize_signature?
        initialize_signature.present?
      end

      def initialize_signature
        return if attributes.blank?

        attributes.map { |attr| "#{attr.name}:" }.join(", ")
      end

      def initialize_body
        attributes.map { |attr| "@#{attr.name} = #{attr.name}" }.join("\n    ")
      end

      def initialize_call_method_for_inline?
        options["call"]
      end

      def inline_template?
        options["inline"]
      end

      def template_engine
        options["template_engine"]
      end

      def default_parent_class
        defined?(ApplicationComponent) ? ApplicationComponent : ViewComponent::Base
      end
    end
  end
end
