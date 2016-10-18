$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'pry'
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
