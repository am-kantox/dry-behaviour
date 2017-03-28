$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'pry'
require 'dry/behaviour'

module Protocols
  module Adder
    include Dry::Protocol

    defprotocol do
      defmethod :add, :this, :other
      defmethod :subtract, :this, :other
      defmethod :crossreferenced, :this
      defmethod :to_s, :this
      defmethod :foo, :this

      def add_default(value)
        add(3, 2) + value
      end

      def foo(this)
        "★#{this}★"
      end
    end

    defimpl Protocols::Adder, target: String do
      def add(this, other)
        this * other
      end

      def subtract(this, _other)
        this
      end
    end

    defimpl target: [Integer, Float], delegate: :to_s, map: { add: :+, subtract: :- } do
      def crossreferenced(this)
        add(add_default(this), this)
      end

      def foo(this)
        super(this)
      end
    end
  end
end

Dry::Protocol.defimpl Protocols::Adder, target: NilClass do
  def add(_this, other)
    other
  end

  def subtract(this, _other)
    this
  end

  def to_s(this)
    this.to_s
  end

  def foo(_this)
    '☆nil☆'
  end

  def add_default(value)
    add(13, 42) + value
  end

  def crossreferenced(this)
    add(this, add_default(5))
  end
end
