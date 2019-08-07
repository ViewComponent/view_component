require "bundler/setup"
require "pp"
require "pathname"
root_path = Pathname(File.expand_path("../..", __FILE__))
$LOAD_PATH.unshift root_path.join("lib").to_s
require "actionview-component"
require "minitest/autorun"
require "action_controller"

def render_component(component, &block)
  Nokogiri::HTML(component.render_in(ActionController::Base.new.view_context, &block))
end
