require 'hatt'

describe Hatt do
  before(:each) do
    Hatt.hatt_initialize
  end

  it 'should have configuration' do
    subject.should respond_to :hatt_configuration
    subject.hatt_configuration.should be_a Hash
  end

  context 'a service name yourapi is configured' do
    before(:each) do
      subject.hatt_add_service 'yourapi', 'https://yourapi.com'
    end

    it 'should get a class method for service yourapi' do
      subject.hatt_build_client_methods
      subject.should respond_to :yourapi
      subject.yourapi.should be_a Hatt::HTTP
      subject.yourapi.should respond_to :get
    end
  end

  context 'a hatt file is given' do
    before(:each) do
      subject.hatt_load_hatt_file SingleHattFile
    end

    it 'should have a method named gmethod' do
      Hatt.should respond_to :gmethod
      Hatt.gmethod.should == 'gmethod returned this'
    end
  end

  context 'initializing from the working directory' do
    before(:each) do
      @orig_working_dir = Dir.pwd
      Dir.chdir FullExampleDir
      Hatt.hatt_initialize
    end

    after(:each) do
      Dir.chdir @orig_working_dir
    end

    it 'should get services from the working directory' do
      Hatt.should respond_to :myapi
    end

    it 'should get hatt methods' do
      Hatt.should respond_to :a_hatt_method
      Hatt.a_hatt_method('x').should eql 'return value'
    end
  end

  context 'initializing from a config file not in working directory' do
    before(:each) do
      Hatt.hatt_config_file FullExampleFile
      Hatt.hatt_initialize
    end

    it 'should respond to services' do
      Hatt.should respond_to :myapi
    end

    it 'should get hatt methods' do
      Hatt.should respond_to :a_hatt_method
      Hatt.a_hatt_method('x').should eql 'return value'
    end
  end

  describe '#run_script_file' do
    before(:each) do
      Hatt.hatt_config_file FullExampleFile
      Hatt.hatt_initialize
    end

    it 'should produce an exception if given non-existent file' do
      expect { Hatt.run_script_file 'fake_file.rb' }.to raise_error(ArgumentError)
    end

    it 'should allow return what the script returns' do
      rtn = Hatt.run_script_file SimpleHattScript
      rtn.should == 42
    end

    it 'should allow a script to call hatt dsl methods' do
      rtn = Hatt.run_script_file DSLCallHattScript
      rtn.should == 'return value'
    end
  end

  describe '#new method' do
    it 'should allow creating a new hatt instance' do
      new_instance = Hatt.new config_file: FullExampleFile
      expect(new_instance.respond_to?(:myapi)).to be true
    end
  end
end
