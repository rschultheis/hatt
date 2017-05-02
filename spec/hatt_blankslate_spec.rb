require 'hatt/blankslateproxy'

describe Hatt::BlankSlateProxy do
  it 'should require a parent instance for .new' do
    expect { Hatt::BlankSlateProxy.new }.to raise_error(ArgumentError)
    expect { Hatt::BlankSlateProxy.new('abc') }.not_to raise_error
    # this nil case is tricky, but I think it is ok.  nil is an object,
    # so using nil as the parent to proxy to seems correct
    expect { Hatt::BlankSlateProxy.new(nil) }.not_to raise_error
  end

  it 'should support respond_to? for public methods on the parent' do
    bsp = Hatt::BlankSlateProxy.new(1)
    # a public method for FixNum
    expect(bsp.respond_to?(:odd?)).to be true
    # a private method for FixNum
    expect(bsp.respond_to?(:fork)).to be false
  end

  it 'should support respond_to? for private methods on the parent if the optional second parameter is true' do
    bsp = Hatt::BlankSlateProxy.new(1)
    # a public method for FixNum
    expect(bsp.respond_to?(:odd?, true)).to be true
    # a private method for FixNum
    expect(bsp.respond_to?(:fork, true)).to be true
  end

  it 'should proxy methods to the parent if they are defined on the parent' do
    bsp = Hatt::BlankSlateProxy.new(1)
    expect(bsp.even?).to be false
    expect(bsp + 2).to be 3
  end

  it 'should proxy methods not defined in parent, but in Object to Object' do
    bsp = Hatt::BlankSlateProxy.new(1)
    expect(bsp.is_a?(Hatt::BlankSlateProxy)).to be true
  end

  it 'should raise error as usual for completely undefined methods' do
    bsp = Hatt::BlankSlateProxy.new(1)
    expect { bsp.some_made_up_method }.to raise_error(NoMethodError)
  end
end
