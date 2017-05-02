require 'hatt/dsl'

describe Hatt::DSL do
  subject { Class.new { include Hatt::DSL }.new }

  describe '#hatt_load_hatt_file' do
    it "should instantiate instance methods on a class including '#{described_class}'" do
      subject.hatt_load_hatt_file SingleHattFile
      subject.should respond_to :gmethod
      subject.gmethod.should == 'gmethod returned this'
    end

    it 'should raise an exception if given a non-existent hatt file' do
      expect { subject.hatt_load_hatt_file SingleHattFile + 'x' }.to raise_error(Hatt::HattNoSuchHattFile)
    end

    it 'should load hatt files so that their directory is in the LOAD_PATH' do
      # load a hatt file that requires another file in it's directory
      subject.hatt_load_hatt_file HattFileWithARequire
      subject.get_that_contstant.should == 'testing is using is testing is using'
    end
  end

  describe '#hatt_load_hatt_glob' do
    it 'should load all the hatt files in a directory' do
      subject.hatt_load_hatt_glob SampleHattGlob
      %i[my_location weather_for my_weather kelvin_to_celcius my_temperature].each do |hatt_method|
        subject.should respond_to hatt_method
      end
    end
  end

  describe 'loading hatt files from configuration' do
    before(:each) do
      @orig_working_dir = Dir.pwd
    end

    after(:each) do
      Dir.chdir @orig_working_dir
    end

    it 'should load the hatt files based on configuration from the working directory' do
      Dir.chdir FullExampleDir
      subject.load_hatts_using_configuration
      subject.should respond_to :a_hatt_method
      subject.a_hatt_method('1').should eql 'return value'
    end

    it 'should load the hatt files based on the config file location even if its not in working directory' do
      subject.hatt_config_file FullExampleFile
      subject.load_hatts_using_configuration
      subject.should respond_to :a_hatt_method
      subject.a_hatt_method('1').should eql 'return value'
    end
  end

  describe 'managing state in hatts' do
    it 'will not allow flat lexical scoping within a hatt' do
      subject.hatt_load_hatt_file HattFileWithState
      expect { subject.get_current_state}.to raise_error(NameError)
    end

    it 'should allow hatts to make and use instance variables' do
      subject.hatt_load_hatt_file HattFileWithState
      subject.get_instance_var.should eql 100
      subject.increment_instance_var
      subject.get_instance_var.should eql 200
    end

    it "should allow hatts to make and use keys in a constant hash" do
      subject.hatt_load_hatt_file HattFileWithState
      subject.get_hash_state_value.should eql 1000
      subject.increment_hash_state_value
      subject.get_hash_state_value.should eql 2000
    end
    
  end
end
