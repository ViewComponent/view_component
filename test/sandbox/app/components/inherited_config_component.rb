# frozen_string_literal: true

class InheritedConfigComponent < ConfigBaseComponent
  configure do
    preview.paths << "another_expected_path"
  end
end
