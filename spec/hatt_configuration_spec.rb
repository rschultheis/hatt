require 'hatt/configuration'

describe Hatt::Configuration do
  subject { Class.new { include Hatt::Configuration }.new }

  # these specs involve changing around the working directory
  # to pick up tcfg.yml / tcfg.secret.yml by default
  before(:each) do
    @orig_working_dir = Dir.pwd
  end

  after(:each) do
    Dir.chdir @orig_working_dir
  end

  context 'hatt.yml is not in current working directory' do
    it 'should return a blank configuration, with an empty services hash default hatt globs and nil for hatt_config_file' do
      subject.hatt_configuration.should == { 'hatt_services' => {}, 'hatt_globs' => ['*hattdsl/*hattdsl.rb'], 'hatt_config_file' => nil }
    end
  end

  it 'should get configuration fron config file if given a valid config file' do
    subject.hatt_config_file FullExampleFile
    subject.hatt_configuration['hatt_services']['myapi']['url'].should eql 'https://my.api.com'
  end

  it 'should raise an error if given a non-existent config file' do
    expect { subject.hatt_config_file 'xxx.yml' }.to raise_error(TCFG::NoSuchConfigFileError)
  end

  context 'hatt.yml is in current working directory' do
    before(:each) do
      Dir.chdir FullExampleDir
    end

    it 'should have configuration from hatt.yml' do
      subject.hatt_configuration.should_not == {}
      subject.hatt_configuration.should have_key 'hatt_services'
    end

    it 'should not include the hatt_environments configuration' do
      subject.hatt_configuration.should_not have_key 'environments'
      subject.hatt_configuration.should_not have_key 'hatt_environments'
    end

    it "should use 'HATT_ENVIRONMENT' to load configuration for a given environment" do
      ENV['HATT_ENVIRONMENT'] = 'qa'
      subject.hatt_configuration['hatt_services']['myapi']['url'].should eql 'http://qa.my.api.com'
      subject.hatt_configuration['hatt_services']['myotherapi']['url'].should eql 'https://my.other.api.net'
    end

    it 'should throw a TCFG error if environment is not specified' do
      ENV['HATT_ENVIRONMENT'] = 'qax'
      expect { subject.hatt_configuration }.to raise_error(TCFG::NoSuchEnvironmentError)
    end

    it 'should allow forcing a url for a service through environment variable overrides' do
      ENV['HATT_hatt_services-myapi-url'] = 'http://override.com'
      subject.hatt_configuration['hatt_services']['myapi']['url'].should == 'http://override.com'
    end
  end

  describe 'resolving configuration' do
    before(:each) do
      subject.hatt_config_file FullExampleFile
    end

    it 'each service should get resolved configuration' do
      services = subject.hatt_configuration['hatt_services']
      services.values.each do |scfg|
        scfg.should have_key 'name'
        scfg.should have_key 'base_uri'
        scfg.should have_key 'faraday_url'
        expect { URI.parse scfg['faraday_url'] }.to_not raise_error
      end
    end
  end
end
