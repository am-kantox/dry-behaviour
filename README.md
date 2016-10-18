# Dry::Behaviour

[![Build Status](https://travis-ci.org/am-kantox/dry-behaviour.svg?branch=master)](https://travis-ci.org/am-kantox/dry-behaviour) | **Tiny library inspired by Elixir [`protocol`](http://elixir-lang.org/getting-started/protocols.html) pattern.**

## Declaration

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

    defimpl Protocols::Adder, for: String do
      def add(this, other)
        this * other
      end
      def subtract(this, other)
        this
      end
    end
    defimpl Protocols::Adder, for: NilClass do
      def add(this, other)
        other
      end
      def subtract(this, other)
        this
      end
    end

    defimpl for: Integer do
      def add(this, other)
        this + other
      end
      def subtract(this, other)
        this - other
      end
    end
  end
end
```

## Usage

```ruby
expect(Protocols::Adder.add(5, 3)).to eq(8)
expect(Protocols::Adder.add(5, 10)).to eq(15)
expect(Protocols::Adder.subtract(5, 10)).to eq(-5)
expect(Protocols::Adder.add(15, 10)).to eq(25)
expect(Protocols::Adder.add("!", 10)).to eq("!!!!!!!!!!")
expect(Protocols::Adder.add(nil, 10)).to eq(10)

expect(Protocols::Adder.add_default(1)).to eq(6)
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
