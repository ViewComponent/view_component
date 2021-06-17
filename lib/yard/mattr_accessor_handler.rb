# frozen_string_literal: true

module YARD
  # YARD Handler to parse `mattr_accessor` calls.
  class MattrAccessorHandler < YARD::Handlers::Ruby::Base
    handles method_call(:mattr_accessor)
    namespace_only

    process do
      name = statement.parameters.first.jump(:tstring_content, :ident).source
      object = YARD::CodeObjects::MethodObject.new(namespace, name)
      register(object)
      parse_block(statement.last, owner: object)

      object.dynamic = true
      object[:mattr_accessor] = true
    end
  end
end
