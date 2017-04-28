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
  end
end
