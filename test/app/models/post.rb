# frozen_string_literal: true

require "action_text/attribute"

class Post
  include ActiveModel::Model
  include ActionText::Attribute
  include ActiveRecord::Associations

  attr_accessor :title, :content

  class << self
    def dangerous_attribute_method?(name)
      false
    end
    def pluralize_table_names; end
    def generated_association_methods; end
    def before_destroy(name); end
    def add_autosave_association_callbacks(name); end
    def clear_reflections_cache; end
    def _reflections
      self
    end
    def _reflections=(name); end
    def except(klass)
      {}
    end
    def scope(name, othername); end

  end

    has_rich_text :content

end
