module ViewComponentHelper
  # For each component, define an helper that renders the component
  # Forward arguments, keywords and block
  Dir[Rails.root.join("app/components/*.rb")].each { |file| require file }
  ViewComponent::Base.subclasses.each do |component|
    method_name = component.name.underscore.tr('/', '_')
    define_method(method_name) do |*args, &block|
      render(component.new(*args), &block)
    end
    ruby2_keywords(method_name) if respond_to?(:ruby2_keywords, true)
  end
end
