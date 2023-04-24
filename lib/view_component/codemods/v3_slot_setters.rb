# Usage (in rails console):
#
# Run the codemod:
#
#     ViewComponent::Codemods::V3SlotSetters.new.call
#
# If your app uses custom paths for views, you can pass them in:
#
#     ViewComponent::Codemods::V3SlotSetters.new(
#       view_path: "../app/views",
#     ).call

module ViewComponent
  module Codemods
    class V3SlotSetters
      TEMPLATE_LANGUAGES = %w[erb slim haml].join(",").freeze
      RENDER_REGEX = /render[( ](?<component>\w+(?:::\w+)*)\.new[) ]+(do|\{) \|(?<arg>\w+)\b/ # standard:disable Lint/MixedRegexpCaptureTypes

      Suggestion = Struct.new(:file, :line, :message)

      def initialize(view_component_path: [], view_path: [])
        Zeitwerk::Loader.eager_load_all

        @view_component_path = view_component_path
        @view_path = view_path
      end

      def call
        puts "Using ViewComponent path: #{view_component_paths.join(", ")}"
        puts "Using Views path: #{view_paths.join(", ")}"
        puts "#{view_components.size} ViewComponents found"
        puts "#{slottable_components.size} ViewComponents using Slots found"
        puts "#{view_component_files.size} ViewComponent templates found"
        puts "#{view_files.size} view files found"
        process_all_files
      end

      def process_all_files
        all_files.each do |file|
          process_file(file)
        end
      end

      def process_file(file)
        @suggestions = []
        @suggestions += scan_exact_matches(file)
        @suggestions += scan_uncertain_matches(file)

        if @suggestions.any?
          puts
          puts "File: #{file}"
          @suggestions.each do |s|
            puts "=> line #{s.line}: #{s.message}"
          end
        end
      end

      private

      def scan_exact_matches(file)
        [].tap do |suggestions|
          rendered_components = []
          content = File.read(file)

          if (render_match = content.match(RENDER_REGEX))
            component = render_match[:component]
            arg = render_match[:arg]

            if registered_slots.key?(component.constantize)
              used_slots_names = registered_slots[component.constantize]
              rendered_components << {component: component, arg: arg, slots: used_slots_names}
            end
          end

          File.open(file) do |f|
            f.each_line do |line|
              rendered_components.each do |rendered_component|
                arg = rendered_component[:arg]
                slots = rendered_component[:slots]

                if (matches = line.scan(/#{arg}\.#{Regexp.union(slots)}/))
                  matches.each do |match|
                    suggestions << Suggestion.new(file, f.lineno, "probably replace `#{match}` with `#{match.gsub("#{arg}.", "#{arg}.with_")}`")
                  end
                end
              end
            end
          end
        end
      end

      def scan_uncertain_matches(file)
        [].tap do |suggestions|
          File.open(file) do |f|
            f.each_line do |line|
              if (matches = line.scan(/(?<!\s)\.(?<slot>#{Regexp.union(all_registered_slot_names)})/))
                next if matches.size == 0

                matches.flatten.each do |match|
                  next if @suggestions.find { |s| s.file == file && s.line == f.lineno }

                  suggestions << Suggestion.new(file, f.lineno, "maybe replace `.#{match}` with `.with_#{match}`")
                end
              end
            end
          end
        end
      end

      def view_components
        ViewComponent::Base.descendants
      end

      def slottable_components
        view_components.select do |comp|
          comp.registered_slots.any?
        end
      end

      def registered_slots
        @registered_slots ||= {}.tap do |slots|
          puts
          puts "Detected slots:"
          slottable_components.each do |comp|
            puts "- `#{comp}` has slots: #{comp.registered_slots.keys.join(", ")}"
            slots[comp] = comp.registered_slots.map do |slot_name, slot|
              normalized_slot_name(slot_name, slot)
            end
          end
        end
      end

      def all_registered_slot_names
        @all_registered_slot_names ||= registered_slots.values.flatten.uniq
      end

      def view_component_files
        Dir.glob(Rails.root.join(view_component_path_glob, "**", "*.{rb,#{TEMPLATE_LANGUAGES}}"))
      end

      def view_files
        Dir.glob(Rails.root.join(view_path_glob, "**", "*.{#{TEMPLATE_LANGUAGES}}"))
      end

      def all_files
        view_component_files + view_files
      end

      def view_component_paths
        @view_component_paths ||= [
          Rails.application.config.view_component.view_component_path,
          @view_component_path
        ].flatten.compact.uniq
      end

      def view_component_path_glob
        return view_component_paths.first if view_component_paths.size == 1

        "{#{view_component_paths.join(",")}}"
      end

      def view_paths
        @view_paths ||= [
          "app/views",
          @view_path
        ].flatten.compact.uniq
      end

      def view_path_glob
        return view_paths.first if view_paths.size == 1

        "{#{view_paths.join(",")}}"
      end

      def normalized_slot_name(slot_name, slot)
        slot[:collection] ? ActiveSupport::Inflector.singularize(slot_name) : slot_name.to_s
      end
    end
  end
end
