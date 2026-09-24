# frozen_string_literal: true

# Deliberately does not include `ViewComponent::ExperimentallyCacheable`, so
# nothing registers it with the digest tree.
class UntrackedChildComponent < ViewComponent::Base
end
