require_relative 'http'
require_relative 'configuration'

module Hatt
  module ApiClients
    include Hatt::Configuration

    def hatt_build_client_methods
      hatt_configuration[:hatt_services].each_pair do |svc, svc_cfg|
        hatt_add_service svc, svc_cfg
      end
    end

    # add a service to hatt
    #
    # @param name [String] the name of the service
    # @param url [String] an absolute url to the api
    def hatt_add_service(name, url_or_svc_cfg_hash)
      svc_cfg = case url_or_svc_cfg_hash
                when String
                  { 'url' => url_or_svc_cfg_hash }
                when Hash
                  url_or_svc_cfg_hash
                else
                  raise ArgumentError, "'#{url_or_svc_cfg_hash}' is not a url string nor hash with url key"
                end

      init_config
      services_config = hatt_configuration['hatt_services']
      services_config[name] = svc_cfg
      @hatt_configuration.tcfg_set 'hatt_services', services_config

      @hatt_http_clients ||= {}
      @hatt_http_clients[name] = Hatt::HTTP.new hatt_configuration['hatt_services'][name]
      define_singleton_method name.intern do
        @hatt_http_clients[name]
      end
    end
  end
end
