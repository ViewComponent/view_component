class MyPreviewController < ViewComponentsController

  def index
    if user_has_access?
      super
    else
      head 403
    end
  end

  private

  def user_has_access?
    false
  end
end
