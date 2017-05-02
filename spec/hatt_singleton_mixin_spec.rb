require 'hatt/singleton_mixin'

describe Hatt::SingletonMixin do
  def build_new_obj_with_hatt_singleton_mixed_in
    obj = Class.new { include Hatt::SingletonMixin }.new
    obj.hatt_config_file FullExampleFile
    obj.hatt_initialize
    obj
  end

  before(:all) do
    @hatt_obj_1 = build_new_obj_with_hatt_singleton_mixed_in
    @hatt_obj_2 = build_new_obj_with_hatt_singleton_mixed_in
  end

  describe 'singleton' do
    it 'should let headers of one not change the other' do
      @hatt_obj_1.myapi.headers['X-MyHeader'] = '123'
      expect(@hatt_obj_1.myapi.headers['X-MyHeader']).to eq '123'
      expect(@hatt_obj_2.myapi.headers['X-MyHeader']).to eq '123'
    end

    it 'should not use the same instance vars in dsl files' do
      @hatt_obj_1.increment_the_state_var
      expect(@hatt_obj_1.show_the_state_var).to eq(1)
      expect(@hatt_obj_2.show_the_state_var).to eq(1)
    end
  end

  describe 'respond_to?' do
    it 'should support respond_to? for public methods on the hatt mixin' do
      expect(@hatt_obj_1.respond_to?(:show_the_state_var)).to be true
      expect(@hatt_obj_1.respond_to?(:fork)).to be false
    end

    it 'should support respond_to? for private methods if the optional second parameter is true' do
      # a public method for FixNum
      expect(@hatt_obj_1.respond_to?(:show_the_state_var, true)).to be true
      # a private method for FixNum
      expect(@hatt_obj_1.respond_to?(:fork, true)).to be true
    end

    it 'should raise error as usual for completely undefined methods' do
      expect { @hatt_obj_1.some_made_up_method }.to raise_error(NoMethodError)
    end
  end
end
