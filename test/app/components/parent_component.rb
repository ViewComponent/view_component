class ParentComponent < ViewComponent::Base
  def self.inherited(child)
    super
  end
end