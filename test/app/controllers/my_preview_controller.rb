class MyPreviewController < ViewComponentsController

  def index
    if user_has_access?
      super
    else
      raise ActionController::Forbidden
    end
  end

  private

  def user_has_access?
    false
  end
end
