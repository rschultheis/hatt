require 'hatt/mixin'

describe Hatt::Mixin do
  def build_new_obj_with_hatt_mixed_in
    obj = Class.new { include Hatt::Mixin }.new
    obj.hatt_config_file FullExampleFile
    obj.hatt_initialize
    obj
  end

  describe 'basic stuff mixin can do' do
    subject { build_new_obj_with_hatt_mixed_in }

    it 'should load apis defined in hatt.yml' do
      expect(subject.respond_to?(:myapi)).to be true
    end

    it 'should load dsl methods' do
      expect(subject.respond_to?(:a_hatt_method)).to be true
      expect(subject.a_hatt_method(nil)).to eql 'return value'
    end

    it 'should have configuration methods' do
      expect(subject.respond_to?(:hatt_configuration)).to be true
      hatt_cfg = subject.hatt_configuration
      expect(hatt_cfg).to be_a Hash
      expect(hatt_cfg[:hatt_config_file]).to eql FullExampleFile
    end

    it 'should have logging methods' do
      expect(subject.respond_to?(:debug)).to be true
      subject.debug 'testing a log message from a spec'
      # hmm, not a great interface for changing log level
      subject.level = :info
    end

    it 'should support the execution of script files' do
      rtn = subject.run_script_file SimpleHattScript
      rtn.should == 42

      rtn = subject.run_script_file DSLCallHattScript
      rtn.should == 'return value'
    end
  end

  describe 'non-singleton' do
    let(:hatt_obj_1) { build_new_obj_with_hatt_mixed_in }
    let(:hatt_obj_2) { build_new_obj_with_hatt_mixed_in }

    it 'should let headers of one not change the other' do
      hatt_obj_1.myapi.headers['X-MyHeader'] = '123'
      expect(hatt_obj_1.myapi.headers['X-MyHeader']).to eq '123'
      expect(hatt_obj_2.myapi.headers['X-MyHeader']).to eq nil
    end

    it 'should not use the same instance vars in dsl files' do
      hatt_obj_1.increment_the_state_var
      expect(hatt_obj_1.show_the_state_var).to eq(1)
      expect(hatt_obj_2.show_the_state_var).to eq(0)
    end
  end
end
