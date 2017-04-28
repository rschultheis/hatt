module Hatt
  # A simple 'blankslate' class which is used to avoid namespace polution
  # TODO: Figure out if can/should use a BasicObject here.  I know it wont work right now
  # because the binding method of Object is needed and not in BasicObject
  class BlankSlate < Object
    def initialize(parent)
      @parent = parent
    end

    def method_missing(method_id, *arguments, &block)
      if parent_has_method?(method_id)
        @parent.send(method_id, *arguments, &block)
      else
        super
      end
    end

    def parent_has_method?(name, include_private = false)
      if include_private
        @parent.methods.include?(name.to_sym)
      else
        @parent.public_methods.include?(name.to_sym)
      end
    end

    def respond_to_missing?(name, include_private = false)
      parent_has_method?(name, include_private) || super
    end
  end
end

