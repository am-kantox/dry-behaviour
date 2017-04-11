require 'spec_helper'

describe Dry::Guards do
  let(:gt) { GuardTest.new }

  it 'permits function overriding' do
    expect(GuardTest.guarded_methods.size).to eq(1)
    expect(GuardTest.guarded_methods.keys).to match_array(%i(a))
    expect(GuardTest.guarded_methods.first.last.size).to eq(7)
  end

  it 'does not affect non guarded functions' do
    expect(gt.b(42)).to eq('NOT GUARDED')
  end

  it 'performs routing to function clauses as by guards' do
    expect(gt.a(42, 'Hello')).to eq(1)
    expect(gt.a(42)).to eq(2)
    expect(gt.a(3.14)).to eq(3)
    expect(gt.a(3)).to eq(4)
    # expect(gt.a('Hello', &-> { puts 0 })).to eq(5) NYI
    expect(gt.a(*%w|1 2 3|)).to eq(6)
    expect(gt.a('Hello')).to eq('ALL')
  end
end
