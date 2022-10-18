# frozen_string_literal: true

module ViewComponent
  module SilenceRedefinitionOfMethodMonkeyPatch
    def silence_redefinition_of_method(method)
      if method_defined?(method) || private_method_defined?(method)
        # This suppresses the "method redefined" warning; the self-alias
        # looks odd, but means we don't need to generate a unique name
        alias_method method, method
      end
    end
  end
end
