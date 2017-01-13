require 'spec_helper'

describe Dry::Behaviour do
  it 'has a version number' do
    expect(Dry::Behaviour::VERSION).not_to be nil
  end

  it 'permits protocol definition' do
    expect(Protocols::Adder.add(5, 3)).to eq(8)
    expect(Protocols::Adder.add(5, 10)).to eq(15)
    expect(Protocols::Adder.subtract(5, 10)).to eq(-5)
    expect(Protocols::Adder.add(15, 10)).to eq(25)
    expect(Protocols::Adder.add('¡Yay!', 10)).to eq('¡Yay!¡Yay!¡Yay!¡Yay!¡Yay!¡Yay!¡Yay!¡Yay!¡Yay!¡Yay!')
    expect(Protocols::Adder.add(nil, 10)).to eq(10)

    expect(Protocols::Adder.to_s(5)).to eq('5')
    expect(Protocols::Adder.to_s('¡Yay!')).to eq('¡Yay!')

    expect(Protocols::Adder.add_default(1)).to eq(6)
  end

  it 'responds to `implemented_for?` properly' do
    expect(Protocols::Adder.implementation_for(5)).to be_truthy
    expect(Protocols::Adder.implementation_for(a: 42)).to be_nil
    expect(::Dry::Protocol.implemented_for?(Protocols::Adder, 5)).to eq(true)
    expect(::Dry::Protocol.implemented_for?(Protocols::Adder, [:a, 42])).to eq(false)
  end

  it 'allows to call protocol-wide methods from inside implementation' do
    expect(Protocols::Adder.crossreferenced(nil)).to eq(7)
  end

  it 'throws a meaningful error on wrong usage' do
    expect { Protocols::Adder.hello(5, 42) }.to raise_error(
      Dry::Protocol::NotImplemented,
      'Protocol “Protocols::Adder” does not declare method “hello”.'
    )
    expect { Protocols::Adder.add({}, 42) }.to raise_error(
      Dry::Protocol::NotImplemented,
      'Protocol “Protocols::Adder” is not implemented for “Hash”.'
    )
    expect { Protocols::Adder.hello({}, 42) }.to raise_error(
      Dry::Protocol::NotImplemented,
      'Protocol “Protocols::Adder” does not declare method “hello”.'
    )
    expect { ::Dry::Protocol.implemented_for?(Integer, 5) }.to raise_error(
      ::Dry::Protocol::NotProtocol,
      '“Integer” is not a protocol.'
    )
    expect { Protocols::Adder.crossreferenced(nil, true) } .to raise_error(
      Dry::Protocol::NotImplemented,
      /Protocol “Protocols::Adder” does not declare method “crossreferenced \(wrong number of arguments/
    )
    expect { Protocols::Adder.crossreferenced(42, 3.14) } .to raise_error(
      Dry::Protocol::NotImplemented,
      /Protocol “Protocols::Adder” does not declare method “undefined method `crossreferenced' for 42:/
    )
  end
end
