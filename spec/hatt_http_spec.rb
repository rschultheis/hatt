require 'hatt/http'
require 'faraday/adapter/test'

describe Hatt::HTTP do
  before(:each) do
    # require 'pry';binding.pry
    subject.logger.level = Logger::DEBUG
  end

  let(:test_configuration) do
    {
      name: 'test service',
      hostname: 'totallyfakedomainthatcouldnotpossiblyexist.com',
      port: 80,
      ssl: false,
      ignore_ssl_certificate: false,
      default_headers: {
        X_SomeHeader: 'some_default_value'
      },
      log_headers: true
    }
  end

  subject { described_class.new test_configuration }

  describe 'http methods' do
    # methods without a request body
    %i[
      get
      head
      options
      delete
    ].each do |method|
      it "should have a #{method} method" do
        subject.stubs.send(method, '/testing') { [200, {}, '{"foo": "bar"}'] }
        response = subject.send(method, '/testing')
        response.should be_a Hash
        response.should eql('foo' => 'bar')
      end
    end

    # methods with a json request body
    %i[
      put
      post
      patch
    ].each do |method|
      it "should have a #{method} method" do
        subject.stubs.send(method, '/testing') { [200, {}, '{"foo": "bar"}'] }
        response = subject.send(method, '/testing', 'a_key' => 'a_value')
        response.should be_a Hash
        response.should eql('foo' => 'bar')
      end
    end

    it 'should remember the last request and response' do
      subject.stubs.send(:post, '/testing') { [200, {}, '{"foo": "bar"}'] }
      subject.post '/testing', 'a_key' => 'a_value'
      # subject.last_request.should be_a Net::HTTP::Post
      subject.last_response.status.should eql 200
    end

    it 'should support a timeout option for overriding timeout for a single request' do
      subject.stubs.send(:get, '/testing') { [200, {}, '{"foo": "bar"}'] }
      subject.get '/testing', timeout: 3
    end
  end

  describe 'error handling' do
    before(:each) do
      subject.stubs.get('/testing') { [400, {}, '{"error_code": "400", "error_message": "bad api client, no cookies for you!"}'] }
    end

    it 'should raise a RequestException when a 400 is returned' do
      expect { subject.get '/testing' }.to raise_error(Hatt::RequestException)
    end

    it 'RequestException should know the response code' do
      begin
        subject.get '/testing'
      rescue Hatt::RequestException => exc
        expect(exc.code).to eq 400
      end
    end

    it 'RequestException should know the response body' do
      begin
        subject.get '/testing'
      rescue Hatt::RequestException => exc
        # get the body in object (parsed json) form
        expect(exc.body).to eq('error_code' => '400', 'error_message' => 'bad api client, no cookies for you!')
        # get it in raw, string form
        expect(exc.response.body).to eq('{"error_code": "400", "error_message": "bad api client, no cookies for you!"}')
      end
    end

    it 'RequestException should have a good .to_s method to make for nice reports' do
      begin
        subject.get '/testing'
      rescue Hatt::RequestException => exc
        # get the body in object (parsed json) form
        expect(exc.to_s).to eq 'Hatt::RequestException
ResponseCode: 400
ResponseBody:
{"error_code"=>"400", "error_message"=>"bad api client, no cookies for you!"}'
      end
    end
  end

  describe 'default timeout configuration for the service' do
    it 'should set read_timeout for the http service based on timeout option' do
      timeout_cfg = test_configuration.merge timeout: 2
      new_svc = Hatt::HTTP.new timeout_cfg
      # new_svc.http.read_timeout.should eql 2
    end
  end

  describe 'default header configuration' do
    it 'should specification of default headers' do
      subject.stubs.get('/testing') { [200, {}, '{"foo": "bar"}'] }
      subject.get '/testing'
      request_headers = subject.last_response.env.request_headers
      expect(request_headers).to eq('X_SomeHeader' => 'some_default_value',
                                    'accept' => 'application/json',
                                    'content-type' => 'application/json')
    end
  end

  describe 'using additional_headers option on request' do
    it 'should extend specification of default headers' do
      subject.stubs.get('/testing') { [200, {}, '{"foo": "bar"}'] }
      response = subject.get '/testing',
                             additional_headers: { :"X-A-CustomHeader" => '123abc' }
      request_headers = subject.last_response.env.request_headers
      expect(request_headers).to eq('X_SomeHeader' => 'some_default_value',
                                    'accept' => 'application/json',
                                    'content-type' => 'application/json',
                                    'X-a-customheader' => '123abc')
    end
  end

  describe 'using the headers option to force headers' do
    it 'should override default headers entirely' do
      subject.stubs.get('/testing') { [200, {}, '{"foo": "bar"}'] }
      response = subject.get '/testing',
                             headers: { :"X-A-CustomHeader" => '123abc' }
      request_headers = subject.last_response.env.request_headers
      expect(request_headers).to eq('X-a-customheader' => '123abc')
    end
  end

  describe 'using the form option to post a form' do
    it 'should change the header, and post the body as an encoded form' do
      subject.stubs.post('/test_form_post') { [200, {}, '{"foo": "bar"}'] }
      subject.post '/test_form_post', { field1: 'value1', field2: 123 },
                   form: true
      request_headers = subject.last_response.env.request_headers
      expect(request_headers).to eq('X_SomeHeader' => 'some_default_value',
                                    'accept' => 'application/json',
                                    'content-type' => 'application/x-www-form-urlencoded')
      expect(subject.last_request[:body]).to eq 'field1=value1&field2=123'
    end

    it 'should also support #post_form with the same functionality' do
      subject.stubs.post('/test_form_post') { [200, {}, '{"foo": "bar"}'] }
      subject.post_form '/test_form_post', field1: 'value1', field2: 123
      request_headers = subject.last_response.env.request_headers
      expect(request_headers).to eq('X_SomeHeader' => 'some_default_value',
                                    'accept' => 'application/json',
                                    'content-type' => 'application/x-www-form-urlencoded')
      expect(subject.last_request[:body]).to eq 'field1=value1&field2=123'
    end
  end

  describe 'using query params' do
    it 'should let use query params no problem' do
      subject.stubs.get('/testing') { [200, {}, '{"foo": "bar"}'] }
      response = subject.get '/testing?p1=v1&p2=v2'
      expect(subject.last_response.env.params).to eq('p1' => 'v1', 'p2' => 'v2')
      expect(subject.last_request[:path]).to eq '/testing'
      expect(subject.last_request[:query]).to eq 'p1=v1&p2=v2'
    end

    it 'should pass multiple values of same param through' do
      subject.stubs.get('/testing') { [200, {}, '{"foo": "bar"}'] }
      response = subject.get '/testing?p1=v1&p2=v2&p2=v3'
      expect(subject.last_response.env.params).to eq('p1' => 'v1', 'p2' => %w[v2 v3])
      expect(subject.last_request[:path]).to eq '/testing'
      expect(subject.last_request[:query]).to eq 'p1=v1&p2=v2&p2=v3'
    end
  end

  describe 'base_uri config option' do
    it 'should prepend a configured base uril to all paths' do
      alt_config = test_configuration.clone
      alt_config[:base_uri] = '/somebase'
      http_client = described_class.new alt_config
      http_client.stubs.get('/somebase/testing') { [200, {}, '{"foo": "bar"}'] }
      http_client.get '/testing?p1=v1'
      expect(http_client.last_request[:path]).to eq '/somebase/testing'
      expect(http_client.last_request[:query]).to eq 'p1=v1'
    end
  end

  describe 'parallel requests' do
    it 'should support parallel requests through the #in_parallel method' do
      subject.stubs.get('/testing') { [200, {}, '{"foo": "bar"}'] }
      num_requests = rand(100) + 1
      responses = []
      subject.in_parallel do
        num_requests.times do |_i|
          responses << subject.faraday_connection.get('/testing')
        end
      end
      expect(responses.length).to eq num_requests
      expect(responses).to all(be_a Faraday::Response)
      expect(responses.map{|r| r.status}).to all(eq 200)
    end
  end
end
