require 'spec_helper'

describe Dry::Annotation do
  it 'parces specs' do
    expect(Protocols::Anno.foo1('42')).to eq(42)
  end
end
