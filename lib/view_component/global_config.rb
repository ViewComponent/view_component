module ViewComponent
  GlobalConfig = defined?(Rails) ? Rails.application.config.view_component : Base.config
end
