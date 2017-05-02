require_relative 'mixin'

module Hatt
  module SingletonMixin
    class InitOnceHattClass
      include Hatt::Mixin
    end

    def hatt_instance
      @@hatt_instance ||= InitOnceHattClass.new
    end
    module_function :hatt_instance

    def method_missing(method_id, *arguments, &block)
      if hatt_instance_has_method?(method_id)
        hatt_instance.send(method_id, *arguments, &block)
      else
        super
      end
    end

    def hatt_instance_has_method?(name, include_private = false)
      if include_private
        hatt_instance.methods.include?(name.to_sym)
      else
        hatt_instance.public_methods.include?(name.to_sym)
      end
    end

    def respond_to_missing?(name, include_private = false)
      hatt_instance_has_method?(name, include_private) || super
    end
  end
end
