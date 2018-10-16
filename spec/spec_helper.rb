$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'pry'
require 'dry/behaviour'

class RespondingToA
  def self.to_a
    [42]
  end
end

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

    defimpl target: RespondingToA, delegate: :to_s do
      def add(_this, other)
        other
      end

      def subtract(this, _other)
        this
      end

      def foo(_this)
        '42'
      end

      def add_default(value)
        add(13, 42) + value
      end

      def crossreferenced(this)
        add(this, add_default(5))
      end
    end
  end
end

module Protocols
  module ParentOK
    include Dry::Protocol

    defprotocol do
      defmethod :foo

      def foo(this)
        :ok
      end

      defimpl target: String do
        def foo(this)
          super(this)
        end
      end
    end
  end

  module ParentKO
    include Dry::Protocol

    defprotocol do
      defmethod :foo

      def foo(this)
        :ok
      end

      defimpl target: String do
      end
    end
  end

  module ParentOKImplicit
    include Dry::Protocol

    defprotocol implicit_inheritance: true do
      defmethod :foo

      def foo(this)
        :ok
      end

      defimpl target: String do
      end
    end
  end
end

module Protocols
  module Arity
    include Dry::Protocol

    defprotocol implicit_inheritance: true do
      defmethod :foo0
      defmethod :foo1, :this
      defmethod :foo2, :this, :req, :opt, :req, :rest, :keyrest, :block

      def foo0(this)
        :ok
      end
      def foo1(this)
        :ok
      end
      def foo2(this)
        :ok
      end

      defimpl target: String do
      end
    end
  end
end

module Protocols
  module Anno
    include Dry::Protocol
    include Dry::Annotation

    defprotocol implicit_inheritance: true do
      @spec[(This) :: (Sym | Nil)]
      defmethod :foo1, :this
      @spec[(This), (Str | Nil) :: (Arr)]
      defmethod :foo2, :this, :opt

      def foo1(this)
        :ok
      end
      def foo2(this, name)
        [:ok, name]
      end

      defimpl target: String do
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

  ::BACKTRACE_LINE = __LINE__ + 1
  def crossreferenced(this)
    add(this, add_default(5))
  end
end

################################################################################

class GuardTest
  include Dry::Guards
  # rubocop:disable Metrics/ParameterLists
  # rubocop:disable Lint/UnusedMethodArgument
  # rubocop:disable Lint/DuplicateMethods
  # rubocop:disable Style/EmptyLineBetweenDefs
  def a(p, p2 = nil, *_a, when: { p: Integer, p2: String }, **_b, &cb)
    1
  end
  def a(p, _p2 = nil, *_a, when: { p: Float }, **_b, &cb)
    3
  end
  def a(p, _p2 = nil, *_a, when: { p: ->(v) { v < 42 } }, **_b, &cb)
    4
  end
  def a(p, _p2 = nil, *_a, when: { p: Integer }, **_b, &cb)
    2
  end
  def a(_p, _p2 = nil, *_a, when: { cb: ->(v) { !v.nil? } }, **_b, &cb)
    5
  end
  def a(p1, p2, p3)
    6
  end
  def a(p, _p2 = nil, *_a, **_b, &cb)
    'ALL'
  end

  def b(p, &cb)
    'NOT GUARDED'
  end

  def c(p)
    1
  end
  def c(p, p2)
    2
  end

  def d(p, when: { p: Integer })
    1
  end
  def d(p, when: { p: Float })
    2
  end

  # rubocop:enable Style/EmptyLineBetweenDefs
  # rubocop:enable Lint/DuplicateMethods
  # rubocop:enable Lint/UnusedMethodArgument
  # rubocop:enable Metrics/ParameterLists
end
