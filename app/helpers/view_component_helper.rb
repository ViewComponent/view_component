module ViewComponentHelper
  # For each component, define an helper that renders the component
  # Forward arguments, keywords and block
  ViewComponent::Base.subclasses.each do |component|
    method_name = component.name.underscore.tr('/', '_')
    define_method(method_name) do |*args, **keywords, &block|
      render(component.new(*args, **keywords), &block)
    end
  end
end
