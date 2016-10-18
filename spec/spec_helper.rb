$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'pry'
require 'dry/behaviour'

module Protocols
  defprotocol :adder do
    defmethod :add, :this, :other
    defmethod :subtract, :this, :other
  end
  defimpl :adder, for: String do
    {
      add: ->(this, other) { this * other },
      subtract: ->(this, other) { this  }
    }
  end
  defimpl :adder, for: NilClass do
    {
      add: ->(this, other) { other },
      subtract: ->(this, other) { this  }
    }
  end
  defimpl :adder, for: Integer do
    {
      add: ->(this, other) { this + other },
      subtract: ->(this, other) { this - other }
    }
  end

  module Adder
    class << self
      def add_default(value)
        self.add(3, 2) + value
      end
    end
  end
end
