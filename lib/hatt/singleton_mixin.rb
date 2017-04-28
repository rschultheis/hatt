
module Hatt
  module SingletonMixin
    class InitOnceHattClass
      include Hatt::Mixin
    end

    def hatt_instance
      @@hatt_instance ||= InitOnceHattClass.new
    end
    module_function :hatt_instance

    def self.included(mod)
      hatt_instance.singleton_methods.each do |meth|
        define_method meth do |*args, &block|
          hatt_instance.send(meth, *args, &block)
        end
      end
    end

  end
end


