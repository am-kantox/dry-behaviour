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
    expect(Protocols::Adder.add("Hello!", 10)).to eq("Hello!Hello!Hello!Hello!Hello!Hello!Hello!Hello!Hello!Hello!")
    expect(Protocols::Adder.add(nil, 10)).to eq(10)

    expect(Protocols::Adder.add_default(1)).to eq(6)
  end
end
