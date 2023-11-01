# frozen_string_literal: true

# FRAMEWORK_LOAD_POINTS ought to be empty - we shouldn't have
# autoloaded ActionView::Base during initialization, for example.
FRAMEWORK_LOAD_POINTS.each do |framework, caller|
  warn "#{framework} loaded too soon, from:"
  warn caller
  exit 1
end
