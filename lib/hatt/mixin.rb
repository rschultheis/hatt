require_relative 'configuration'
require_relative 'api_clients'
require_relative 'dsl'
require_relative 'blankslateproxy'

module Hatt
  module Mixin

    include Hatt::Log
    include Hatt::Configuration
    include Hatt::ApiClients
    include Hatt::DSL

    def initialize(*opts)
      hatt_initialize
      super(*opts)
    end

    def hatt_initialize
      hatt_build_client_methods
      load_hatts_using_configuration
      self
    end

    def run_script_file filename
      info "Running data script '#{filename}'"
      raise(ArgumentError, "No such file '#{filename}'") unless File.exist? filename
      # by running in a anonymous class, we protect this class's namespace
      anon_class = BlankSlateProxy.new(self)
      with_local_load_path File.dirname(filename) do
        anon_class.instance_eval(IO.read(filename), filename, 1)
      end
    end

    def launch_pry_repl
      require 'pry'
      binding.pry
    end

  end
end
