require 'active_support'
require_relative 'mixin'
require_relative 'singleton_mixin'

module Hatt
  class << self
    include Hatt::Mixin

    def initialize(*args)
      super(*args)
    end

    def new options={}
      options = ActiveSupport::HashWithIndifferentAccess.new options
      hatt_instance = Class.new { include Hatt::Mixin }.new
      hatt_instance.hatt_config_file options.fetch(:config_file, 'hatt.yml')
      hatt_instance.hatt_initialize
      hatt_instance
    end
  end
end
