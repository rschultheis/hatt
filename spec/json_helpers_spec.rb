require 'hatt/json_helpers.rb'

describe Hatt::JsonHelpers do
  let(:json_helper) { Class.new.extend(Hatt::JsonHelpers) }

  describe :jsonify do
    it 'should turn a hash into json' do
      hash = {
        'a' => '123',
        'b' => 456,
        :c => [
          1,
          2.3,
          '456'
        ],
        'd' => {
          'x' => 'y'
        }
      }

      json = json_helper.jsonify(hash)

      # ugh, gross!
      json.should eql %({
  "a": "123",
  "b": 456,
  "c": [
    1,
    2.3,
    "456"
  ],
  "d": {
    "x": "y"
  }
})
    end

    it 'should return a non json string as itself' do
      json_helper.jsonify('abc').should eql('abc')
    end

    it 'should make a json string pretty' do
      json_str = '{"foo":"bar", "abc":123}'
      json_helper.jsonify(json_str).should eql %({
  "foo": "bar",
  "abc": 123
})
    end
  end

  describe :objectify do
    it 'should turn a json map string into a Hash' do
      hsh = { 'str' => 'abc', 'int' => 123, 'dec' => 12.34, 'bool' => true }
      json = JSON.generate hsh
      json_helper.objectify(json).should eql hsh
    end

    it 'turn a json array string into an Array' do
      arr = [1, 2.34, 'three', true]
      json = JSON.generate arr
      json_helper.objectify(json).should =~ arr
    end

    it 'should return a non-string object as itself' do
      obj = 12.34
      json_helper.objectify(obj).should eql obj
    end

    it 'should return a hash or array as itself' do
      obj = [123, 456]
      json_helper.objectify(obj).should eql obj
      obj = {abc: 123, def: 456}
      json_helper.objectify(obj).should eql obj
    end

    it 'should return a non-json string as itself' do
      str = 'abc;123'
      json_helper.objectify(str).should eql str
    end

    it 'should return nil as nil' do
      json_helper.objectify(nil).should eql nil
    end

    it 'should return an empty string as nil' do
      json_helper.objectify('').should eql nil
    end
  end
end
