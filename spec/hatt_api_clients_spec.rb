require 'hatt/api_clients'

describe Hatt::ApiClients do
  subject { Class.new { include Hatt::ApiClients }.new }

  describe '#hatt_add_service' do
    it 'should allow specifying services through a method call' do
      subject.hatt_add_service 'mynewapi', 'http://api.my.new.io'
      subject.hatt_configuration['hatt_services'].should have_key 'mynewapi'
      subject.hatt_add_service 'myextranewapi', 'http://api.my.new.us'
      subject.hatt_configuration['hatt_services'].should have_key 'mynewapi'
      subject.hatt_configuration['hatt_services'].should have_key 'myextranewapi'
    end

    it 'should raise an error if url is not absolute' do
      expect { subject.hatt_add_service 'mynewapi', 'xxx' }.to raise_error(Hatt::ConfigurationError)
    end

    it 'should raise an error if no url given with service config' do
      expect { subject.hatt_add_service 'mynewapi', urlx: 'http://mistake.com' }.to raise_error(Hatt::ConfigurationError)
    end

    it 'should raise an error if config parameter is not a url string or hash' do
      expect { subject.hatt_add_service 'mynewapi', 123 }.to raise_error(ArgumentError)
    end
  end
end
