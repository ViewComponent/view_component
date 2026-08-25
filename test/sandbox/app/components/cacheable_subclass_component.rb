# frozen_string_literal: true

# Inherits its template from CacheableComponent, so changes to the parent must
# invalidate this component's digest.
class CacheableSubclassComponent < CacheableComponent
end
