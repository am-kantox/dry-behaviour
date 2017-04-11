require 'spec_helper'

describe Dry::Guards do
  it 'permits function overriding' do
    expect(GuardTest.guarded_methods.size).to eq(1)
    expect(GuardTest.guarded_methods.keys).to match_array(%i(a))
    expect(GuardTest.guarded_methods.first.last.size).to eq(6)
  end
end
