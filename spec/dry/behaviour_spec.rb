require 'spec_helper'

# rubocop:disable Metrics/BlockLength
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
    expect(Protocols::Adder.crossreferenced(nil)).to eq(47)
    expect(Protocols::Adder.crossreferenced(RespondingToA.new)).to eq(47)
    expect(Protocols::Adder.crossreferenced(3.14).round(2)).to eq(11.28)
  end

  it 'derives calls from inherited protocol and overrides them' do
    expect(Protocols::Adder.foo(42)).to eq('★42★')
    expect(Protocols::Adder.foo(nil)).to eq('☆nil☆')
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
      Dry::Protocol::NotImplemented, / ⮩    “wrong number of arguments/
    )
    expect { Protocols::Adder.crossreferenced('42', '3.14') } .to raise_error(
      Dry::Protocol::NotImplemented, / ⮩    “undefined method `crossreferenced' for "42"/
    )

    ex =
      begin
        Protocols::Adder.crossreferenced(nil, true)
      rescue => e
        e
      end
    expect(ex.backtrace.first).to \
      be_end_with("dry-behaviour/spec/spec_helper.rb:#{BACKTRACE_LINE}:in `crossreferenced'")
  end

  it 'answers to `respond_to?`' do
    expect(Protocols::Adder.respond_to?(:foo)).to be_truthy
    expect(Protocols::Adder.respond_to?(:baz)).to be_falsey
  end

  it 'allows implicit protocol inheritance' do
    expect(Protocols::ParentOK.respond_to?(:foo)).to be_truthy
    expect { Protocols::ParentOK.foo('42') }.not_to raise_error
    expect { Protocols::ParentKO.foo('42') }.to raise_error(/undefined method `foo' for "42"/)
    expect { Protocols::ParentOKImplicit.foo('42') }.not_to raise_error
    expect(Protocols::ParentOKImplicit.foo('42')).to eq(:ok)
  end

  it 'checks arity of the impleemntation' do
    expect(Protocols::Arity.foo0('42')).to eq(:ok)
    expect(Protocols::Arity.foo1('42')).to eq(:ok)
    expect(Protocols::Arity.foo2('42', '42', '42', '42', '42', foo: :bar)).to eq(:ok)
  end

  it 'works for default and keyword args' do
    expect(Protocols::LaTiaPascuala.method_with_hash_argument(nil, foo: :bar)).to eq(foo: :bar)
    expect(Protocols::LaTiaPascuala.method_with_defaulted_argument(nil)).to eq :super
    expect(Protocols::LaTiaPascuala.method_with_defaulted_keyword_argument(nil)).to eq :super
    expect(Protocols::LaTiaPascuala.method_with_required_keyword_argument(nil, foo_key: 42)).to eq 42

    expect(Protocols::LaTiaPascuala.method_with_hash_argument({hash: :yes}, foo: :bar)).to eq(hash: :yes, foo: :bar)
    expect(Protocols::LaTiaPascuala.method_with_defaulted_argument(hash: :yes)).to eq(hash: :yes, default: :overriden)
    expect(Protocols::LaTiaPascuala.method_with_defaulted_keyword_argument(Hash[:hash, :yes])).to eq(hash: :yes, default: :overriden)
    expect(Protocols::LaTiaPascuala.method_with_required_keyword_argument({hash: :yes}, foo_key: 42)).to eq(hash: :yes, default: 42)

    expect(Protocols::LaTiaPascuala.method_with_hash_argument(true, foo: :bar)).to eq(foo: TrueClass)
    expect(Protocols::LaTiaPascuala.method_with_defaulted_argument(true)).to eq :overriden
    expect(Protocols::LaTiaPascuala.method_with_defaulted_keyword_argument(true)).to eq :overriden
    expect(Protocols::LaTiaPascuala.method_with_required_keyword_argument(true, foo_key: 42)).to eq 42

    expect { Protocols::LaTiaPascuala.method_with_defaulted_argument(false) }.to raise_error(
      Dry::Protocol::NotImplemented, / ⮩    “does matter \(defaulted\)/
    )
    expect { Protocols::LaTiaPascuala.method_with_defaulted_keyword_argument(false, foo_key: 42) }.to raise_error(
      Dry::Protocol::NotImplemented, / ⮩    “does matter \(defaulted keyword\)/
    )
    expect { Protocols::LaTiaPascuala.method_with_required_keyword_argument(false, foo_key: 42) }.to raise_error(
      Dry::Protocol::NotImplemented, / ⮩    “does matter \(required keyword\)/
    )
  end
end
# rubocop:enable Metrics/BlockLength
