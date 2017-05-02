require 'uri'

require 'tcfg/tcfg_base'

module Hatt
  module Configuration

    DEFAULT_CONFIG_FILE = 'hatt.yml'
    DEFAULT_HATT_GLOBS = ['*_hattdsl/*_hattdsl.rb'].freeze

    def hatt_configuration
      init_config
      @hatt_configuration.tcfg
    end

    def hatt_config_file filename
      @hatt_config_file = filename
      init_config
    end

    private

    def hatt_config_file_path
      if @hatt_config_file 
        File.expand_path @hatt_config_file
      elsif File.exist? DEFAULT_CONFIG_FILE
        File.expand_path DEFAULT_CONFIG_FILE
      else
        nil
      end
    end

    # ensure the configuration is resolved and ready to use
    def init_config
      if !@hatt_configuration
        @hatt_configuration = TCFG::Base.new

        # build up some default configuration
        @hatt_configuration.tcfg_set 'hatt_services', {}
        @hatt_configuration.tcfg_set 'hatt_globs', DEFAULT_HATT_GLOBS

        @hatt_configuration.tcfg_set_env_var_prefix 'HATT_'
      end

      if hatt_config_file_path
        # if a config file was specified, we assume it exists
        @hatt_configuration.tcfg_config_file hatt_config_file_path
      else
        Log.warn "No configuration file specified or found. Make a hatt.yml file and point hatt at it."
      end
      @hatt_configuration.tcfg_set 'hatt_config_file', hatt_config_file_path

      normalize_services_config @hatt_configuration

      nil
    end

    def normalize_services_config cfg
      services = cfg['hatt_services']
      services.each_pair do |svc, svc_cfg|
        # add the name
        svc_cfg['name'] = svc

        unless svc_cfg.has_key? :url
          raise ConfigurationError.new "url for service '#{svc_cfg['name']}' is not defined"  
        end

        unless svc_cfg['url'] =~ URI::ABS_URI
          raise ConfigurationError.new "url for service '#{svc_cfg['name']}' is not a proper absolute URL: #{svc_cfg['url']}"
        end

        parsed = URI.parse svc_cfg['url']

        svc_cfg['base_uri'] ||= parsed.path

        svc_cfg['faraday_url'] = "#{parsed.scheme}://#{parsed.host}:#{parsed.port}"
      end

      cfg.tcfg_set 'hatt_services', services
    end

  end

  class ConfigurationError < StandardError;end
end
