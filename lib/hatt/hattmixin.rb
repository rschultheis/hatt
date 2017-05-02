require_relative 'configuration'
require_relative 'api_clients'
require_relative 'dsl'

module Hatt
  module HattMixin
    include Hatt::Configuration
    include Hatt::DSL
    include Hatt::ApiClients

    def initialize(*opts)
      hatt_initialize
      super(*opts)
    end

    def hatt_initialize
      hatt_build_client_methods
      load_hatts_using_configuration
    end
  end
end
