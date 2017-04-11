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

class GuardTest
  include Dry::Guards
  # rubocop:disable Metrics/ParameterLists
  # rubocop:disable Lint/UnusedMethodArgument
  # rubocop:disable Lint/DuplicateMethods
  # rubocop:disable Style/EmptyLineBetweenDefs
  def a(p, p2 = nil, *_a, when: { p: Integer, p2: String }, **_b, &cb)
    1
  end
  def a(p, _p2 = nil, *_a, when: { p: Integer }, **_b, &cb)
    2
  end
  def a(p, _p2 = nil, *_a, when: { p: Float }, **_b, &cb)
    3
  end
  def a(p, _p2 = nil, *_a, when: { p: ->(v) { v < 42 } }, **_b, &cb)
    4
  end
  def a(_p, _p2 = nil, *_a, when: { cb: ->(v) { !v.nil? } }, **_b, &cb)
    5
  end
  def a(p, _p2 = nil, *_a, **_b, &cb)
    'ALL'
  end

  def b(p, &cb)
    'NOT GUARDED'
  end
  # rubocop:enable Style/EmptyLineBetweenDefs
  # rubocop:enable Lint/DuplicateMethods
  # rubocop:enable Lint/UnusedMethodArgument
  # rubocop:enable Metrics/ParameterLists
end
