# frozen_string_literal: true

module ViewComponent
  module SystemSpecHelpers
    include SystemTestHelpers

    def page
      Capybara.current_session
    end
  end
end
