# frozen_string_literal: true

require "bundler/setup"
require "pp"
require "pathname"
require "action_view/component"
require "minitest/autorun"

# Configure Rails Envinronment
ENV["RAILS_ENV"] = "test"

require File.expand_path("../config/environment.rb", __FILE__)
require "rails/test_help"

def trim_result(content)
  content = content.to_s.lines.collect(&:strip).join("\n").strip

  doc = Nokogiri::HTML.fragment(content)

  doc.xpath("//text()").each do |node|
    if node.content.match?(/\S/)
      node.content = node.content.gsub(/\s+/, " ").strip
    else
      node.remove
    end
  end

  doc.to_s.strip
end

def assert_html_matches(expected, actual)
  assert_equal(trim_result(expected), trim_result(actual))
end

def const_source_location_supported?
  Module.respond_to? :const_source_location
end
