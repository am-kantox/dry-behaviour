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

  it 'throws a meaningful error on wrong usage' do
    expect { Protocols::Adder.hello(5, 42)}.to raise_error(
      Dry::Protocol::NotImplemented,
      "Protocol “Protocols::Adder” does not declare method “hello”."
    )
    expect { Protocols::Adder.add({}, 42)}.to raise_error(
      Dry::Protocol::NotImplemented,
      "Protocol “Protocols::Adder” is not implemented for “Hash”."
    )
    expect { Protocols::Adder.hello({}, 42)}.to raise_error(
      Dry::Protocol::NotImplemented,
      "Protocol “Protocols::Adder” does not declare method “hello”."
    )
  end
end
