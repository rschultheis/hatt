require 'faraday'
require 'typhoeus'
require 'typhoeus/adapters/faraday' # https://github.com/typhoeus/typhoeus/issues/226#issuecomment-9919517
require 'active_support/notifications'

require 'yaml'

require_relative 'json_helpers'
require_relative 'log'

module Hatt
  class HTTP
    include Hatt::Log
    include Hatt::JsonHelpers

    def initialize(config)
      @config = config
      @name = @config[:name]
      @base_uri = @config[:base_uri]
      @log_headers = @config.fetch(:log_headers, true)
      @log_bodies = @config.fetch(:log_bodies, true)

      logger.debug "Configuring service:\n#{@config.to_hash.to_yaml}\n"

      @faraday_connection = Faraday.new @config[:faraday_url] do |conn_builder|
        # do our own logging
        # conn_builder.response logger: logger
        # conn_builder.adapter  Faraday.default_adapter  # make requests with Net::HTTP
        conn_builder.adapter @config.fetch(:adapter, :typhoeus).intern
        conn_builder.ssl[:verify] = false if @config[:ignore_ssl_cert]

        # defaulting this to flat adapter avoids issues when duplicating parameters
        conn_builder.options[:params_encoder] = Faraday.const_get(@config.fetch(:params_encoder, 'FlatParamsEncoder'))

        # this nonsense dont work?!  https://github.com/lostisland/faraday_middleware/issues/76
        # conn_builder.use :instrumentation
      end

      @headers = {
        'accept' => 'application/json',
        'content-type' => 'application/json'
      }
      if @config[:default_headers]
        logger.debug 'Default headers configured: ' + @config[:default_headers].inspect
        @config[:default_headers].each_pair do |k, v|
          @headers[k.to_s] = v.to_s
        end
      end
      @default_timeout = @config.fetch(:timeout, 10)
      logger.info "Initialized hatt service '#{@name}'"
    end

    def stubs
      stubs = Faraday::Adapter::Test::Stubs.new
      @faraday_connection = Faraday.new @config[:faraday_url] do |conn_builder|
        conn_builder.adapter :test, stubs
      end
      stubs
    end

    # allow stubbing http if we are testing
    attr_reader :http if defined?(RSpec)
    attr_reader :name, :config, :faraday_connection
    attr_accessor :headers # allows for doing some fancy stuff in threading

    # this is useful for testing apis, and other times
    # you want to interrogate the http details of a response
    attr_reader :last_request, :last_response

    def in_parallel(&blk)
      @faraday_connection.headers = @headers
      @faraday_connection.in_parallel(&blk)
    end

    # do_request performs the actual request, and does associated logging
    # options can include:
    # - :timeout, which specifies num secs the request should timeout in
    #   (this turns out to be kind of annoying to implement)
    def do_request(method, path, obj = nil, options = {})
      # hatt clients pass in path possibly including query params.
      # Faraday needs the query and path seperately.
      parsed_uri = URI.parse make_path(path)
      # faraday needs the request params as a hash.
      # this turns out to be non-trivial
      query_hash = if parsed_uri.query
                     cgi_hash = CGI.parse(parsed_uri.query)
                     # this next line accounts for one param having multiple values
                     cgi_hash.each_with_object({}) { |(k, v), h| h[k] = v[1] ? v : v.first; }
                   end

      req_headers = make_headers(options)

      body = if options[:form]
               URI.encode_www_form obj
             else
               jsonify(obj)
      end


      log_request(method, parsed_uri, query_hash, req_headers, body)

      # doing it this way avoids problem with OPTIONS method: https://github.com/lostisland/faraday/issues/305
      response = nil
      metrics_obj = { method: method, service: @name, path: parsed_uri.path }
      ActiveSupport::Notifications.instrument('request.hatt', metrics_obj) do
        response = @faraday_connection.run_request(method, nil, nil, nil) do |req|
          req.path = parsed_uri.path
          req.params = metrics_obj[:params] = query_hash if query_hash

          req.headers = req_headers
          req.body = body
          req.options[:timeout] = options.fetch(:timeout, @default_timeout)
        end
        metrics_obj[:response] = response
      end

      logger.info "Request status: (#{response.status}) #{@name}: #{method.to_s.upcase} #{path}"
      @last_request = {
        method: method,
        path: parsed_uri.path,
        query: parsed_uri.query,
        headers: req_headers,
        body: body
      }
      @last_response = response

      response_obj = objectify response.body

      log_response(response, response_obj)

      raise RequestException.new(nil, response) unless response.status >= 200 && response.status < 300

      response_obj
    end

    def get(path, options = {})
      do_request :get, path, nil, options
    end

    def head(path, options = {})
      do_request :head, path, nil, options
    end

    def options(path, options = {})
      do_request :options, path, nil, options
    end

    def delete(path, options = {})
      do_request :delete, path, nil, options
    end

    def post(path, obj, options = {})
      do_request :post, path, obj, options
    end

    def put(path, obj, options = {})
      do_request :put, path, obj, options
    end

    def patch(path, obj, options = {})
      do_request :patch, path, obj, options
    end

    def post_form(path, params, options = {})
      do_request :post, path, params, options.merge(form: true)
    end

    # convenience method for accessing the last response status code
    def last_response_status
      @last_response.status
    end

    private

    # add base uri to request
    def make_path(path_suffix)
      if @base_uri
        @base_uri + path_suffix
      else
        path_suffix
      end
    end

    def make_headers(options)
      headers = if options[:additional_headers]
                  @headers.merge options[:additional_headers]
                elsif options[:headers]
                  options[:headers]
                else
                  @headers.clone
      end
      headers['content-type'] = 'application/x-www-form-urlencoded' if options[:form]
      headers
    end

    def log_request(method, parsed_uri, query_hash={}, headers, body)
      # log the request
      logger.debug [
        "Doing request: #{@name}: #{method.to_s.upcase} #{parsed_uri.path}?#{query_hash.is_a?(Hash) ? URI.encode_www_form(query_hash) : ''}",
        @log_headers ? ['Request Headers:',
                        headers.map { |k, v| "#{k}: #{v.inspect}" }] : nil,
        @log_bodies ? ['Request Body:', body] : nil
      ].flatten.compact.join("\n")
    end

    def log_response(response, response_obj)
      log_messages = [
        'Response Details:',
        @log_headers ? ['Response Headers:',
                        response.headers.map { |k, v| "#{k}: #{v.inspect}" }] : nil
      ]
      if response.headers['content-type'] =~ /json/
        log_messages += [
          @log_bodies ? ['Response Body:', jsonify(response_obj)] : nil,
          ''
        ]
      end
      logger.debug log_messages.flatten.compact.join("\n")
    end

  end

  class RequestException < RuntimeError
    include Hatt::JsonHelpers

    def initialize(request, response)
      @request = request
      @response = response
    end
    attr_reader :request, :response

    # this makes good info show up in rspec reports
    def to_s
      "#{self.class}\nResponseCode: #{code}\nResponseBody:\n#{body}"
    end

    # shortcut methods
    def code
      @response.status
    end

    def body
      objectify(@response.body)
    end
  end
end
