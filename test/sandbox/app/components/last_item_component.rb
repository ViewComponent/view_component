class LastItemComponent < ViewComponent::Base
  renders_many :items, "BreadcrumbItemComponent"

  def call
    tag.ul do
      items.last.active = true
      safe_join(items)
    end
  end

  class BreadcrumbItemComponent < ViewComponent::Base
    attr_writer :active

    def initialize(item)
      @item = item
    end

    def call
      html_class = +"breadcrumb"
      html_class << " active" if @active
      tag.li(@item, class: html_class)
    end
  end
end
