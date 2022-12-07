# Dry::Behaviour

[![Build Status](https://travis-ci.org/am-kantox/dry-behaviour.svg?branch=master)](https://travis-ci.org/am-kantox/dry-behaviour)

**Tiny library inspired by Elixir [`protocol`](http://elixir-lang.org/getting-started/protocols.html) pattern.**

## Protocols

### Declaration

```ruby
require 'dry/behaviour'

module Protocols
  module Adder
    include Dry::Protocol

    defprotocol do
      defmethod :add, :this, :other
      defmethod :subtract, :this, :other

      def add_default(value)
        add(3, 2) + value
      end
    end

    defimpl Protocols::Adder, target: String do
      def add(this, other)
        this * other
      end
      def subtract(this, other)
        this
      end
    end
    defimpl Protocols::Adder, target: NilClass do
      def add(this, other)
        other
      end
      def subtract(this, other)
        this
      end
    end

    # delegate `to_s` as is, map `add` and `subtract` to `:+` and `:-` respectively
    defimpl target: Integer, delegate: :to_s, map: { add: :+, subtract: :- }
  end
end
```

### Usage

```ruby
expect(Protocols::Adder.add(5, 3)).to eq(8)
expect(Protocols::Adder.add(5, 10)).to eq(15)
expect(Protocols::Adder.subtract(5, 10)).to eq(-5)
expect(Protocols::Adder.add(15, 10)).to eq(25)
expect(Protocols::Adder.add("!", 10)).to eq("!!!!!!!!!!")
expect(Protocols::Adder.add(nil, 10)).to eq(10)

expect(Protocols::Adder.add_default(1)).to eq(6)
```

### Arguments types

Normally, one would use a simple notation to declare a method. It includes `:this` receiver
in te very first position and some optional required arguments afterward.

```ruby
  defmethod :add, :this, :addend
  ...
  defimpl ... do
    def add(this, addend); this + addend; end
  end
```

If the argument is not generic (optional, or splatted, or keyword,) its type must be explicitly
specified in the protocol definition as shown below.

```ruby
  defprotocol implicit_inheritance: true do
    defmethod :with_def_argument, :this, [:foo_opt, :opt]
    defmethod :with_def_keyword_argument, :this, [:foo_key, :key]
    defmethod :with_req_keyword_argument, :this, [:foo_key, :keyreq]

    def with_def_argument(this, foo_opt = :super); foo_opt; end
    def with_def_keyword_argument(this, foo_key: :super); foo_key; end
    def with_req_keyword_argument(this, foo_key:); foo_key; end
  ...
```

That said, `:addend` argument declaration is a syntactic sugar for `[:addend, :req]`.
Possible values for the type are:

```ruby
PARAM_TYPES = %i[req opt rest key keyrest keyreq block]
```

Please note, that the signature of the method and its implementation must exactly match.
One cannot declare a method to have a `keyreq` argument and then make it defaulted in the
implementation. That is done by design.

## Guards

Starting with `v0.5.0` we support multiple function clauses and guards.

```ruby
class GuardTest
  include Dry::Guards

  def a(p, p2 = nil, *_a, when: { p: Integer, p2: String }, **_b, &cb); 1; end
  def a(p, _p2 = nil, *_a, when: { p: Integer }, **_b, &cb); 2; end
  def a(p, _p2 = nil, *_a, when: { p: Float }, **_b, &cb); 3; end
  def a(p, _p2 = nil, *_a, when: { p: ->(v) { v < 42 } }, **_b, &cb); 4; end
  def a(_p, _p2 = nil, *_a, when: { cb: ->(v) { !v.nil? } }, **_b, &cb); 5; end
  def a(p1, p2, p3); 6; end
  def a(p, _p2 = nil, *_a, **_b, &cb); 'ALL'; end

  def b(p, &cb)
    'NOT GUARDED'
  end
end

gt = GuardTest.new

it 'performs routing to function clauses as by guards' do
  expect(gt.a(42, 'Hello')).to eq(1)
  expect(gt.a(42)).to eq(2)
  expect(gt.a(3.14)).to eq(3)
  expect(gt.a(3)).to eq(4)
  expect(gt.a('Hello', &-> { puts 0 })).to eq(5)
  expect(gt.a(*%w|1 2 3|)).to eq(6)
  expect(gt.a('Hello')).to eq('ALL')
end
```

## Authors

@am-kantox, @saverio-kantox & @kantox

## Changelog

### `0.9.0` :: Warning On Wrong Arity

- many error reporting improvements,
- warning on wrong arity (declaration, arity 0 / implementation, wrong arity)

### `0.8.0` :: Implicit Inheritance

- deprecate implicit delegation to the target instance; error message saying “it’ll be removed in 1.0”
- `implicit_inheritance: true` flag in call to `defprotocol` makes the implementation implicitly inherit the behaviour declared in the core protocol module itself, without the necessity to explicitly call `super`:

```diff
 module ParentOKImplicit
   include Dry::Protocol

-  defprotocol do
+  defprotocol implicit_inheritance: true do
     defmethod :foo

     def foo(this)
       :ok
     end

     defimpl target: String do
-      def foo(this)
-        super(this)
-      end
     end
   end
 end
```

### `0.7.0` :: Handling Errors

- better error messages (very descriptive, with whys and howtos)
- the whole stacktrace is carefully saved with `cause`
- internal exceptions related to wrong implementation do now point to the proper lines in the client code (internal trace lines are removed)

### `0.6.0` :: Bugfix

- implementation for classes responding to **`to_a`** is handled properly

### `0.5.0` :: Guards

### `0.4.2` :: Removed the forgotten debug output :(

### `0.4.1` :: Protocol-wide methods are allowed to call from implementation

**NB** Works for all `defimpl`s.

### `0.4.0` :: Protocol-wide methods are allowed to call from inside implementation

```ruby
module Protocols::Adder
  include Dry::Protocol

  defprotocol do
    defmethod :add, :this, :other
    def default
      42
    end
  end
end

Dry::Protocol.defimpl target: Integer do
  def add(this)
    this + default #⇒ 47 when called as Protocols::Adder.add(5)
  end
end
```

**NB** At the moment works only for external `defimpl`.

### `0.3.1` :: `implemented_for?` and `implementation_for`

### `0.3.0` :: version bump

### `0.2.2` :: meaningful errors

#### Throws an exception on wrong usage:

```ruby
Protocols::Adder.add({}, 42)
#⇒ Protocols::NotImplemented: Protocol “Protocols::Adder” is not implemented for “Hash”
Protocols::Adder.hello({}, 42)
#⇒ Protocols::NotImplemented: Protocol “Protocols::Adder” does not declare method “hello”
```

### `0.2.1` :: multiple targets

#### Multiple targets:

```ruby
defimpl MyProto, target: [MyClass1, MyClass2], delegate: [:add, :subtract]
```

### `0.2.0` :: implicit delegate on incomplete implementation

when `defimpl` does not fully cover the protocol declaration,
missing methods are implicitly delegated to the target,
the warning is being issued:

```ruby
defimpl MyProto, target: MyClass, map: { add: :+, subtract: :- }
#⇒ W, [2016-10-24T14:52:49.230808 #26382]  WARN -- : Implicit delegate MyProto#to_s to MyClass
```

### `0.1.1` :: delegate and map methods to receiver

`defimpl` now accepts `delegate` and `map`:

```ruby
defimpl MyProto, target: MyClass, delegate: :to_s, map: { add: :+, subtract: :- }
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'dry-behaviour'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install dry-behaviour

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/dry-behaviour. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
