require 'dry/behaviour/version'
require 'dry/errors'
require 'dry/behaviour/black_tie'
require 'dry/behaviour/cerberus'

module Dry
  # rubocop:disable Style/AsciiIdentifiers
  # rubocop:disable Style/EmptyCaseCondition
  DEFINE_METHOD = lambda do |target, this, *args, **params, &λ|
    case
    when !args.empty? && !params.empty? then this.send(target, *args, **params, &λ)
    when !args.empty? then this.send(target, *args, &λ)
    when !params.empty? then this.send(target, **params, &λ)
    else this.send(target, &λ)
    end
  end
  # rubocop:enable Style/EmptyCaseCondition
  # rubocop:enable Style/AsciiIdentifiers

  module Protocol
    def self.included(base)
      base.singleton_class.prepend(::Dry::BlackTie)
    end

    class << self
      # rubocop:disable Style/AsciiIdentifiers
      def defimpl(protocol = nil, target: nil, delegate: [], map: {}, &λ)
        Dry::BlackTie.defimpl(protocol, target: target, delegate: delegate, map: map, &λ)
      end
      # rubocop:enable Style/AsciiIdentifiers

      # rubocop:disable Style/RaiseArgs
      def implemented_for?(protocol, receiver)
        raise ::Dry::Protocol::NotProtocol.new(protocol) unless protocol < ::Dry::Protocol
        !protocol.implementation_for(receiver).nil?
      end
      # rubocop:enable Style/RaiseArgs
    end
  end

  module Guards
    def self.included(base)
      ::Dry::Cerberus::POSTPONE_FIX_CLAUSES.(base)
      base.singleton_class.prepend(::Dry::Cerberus)
    end
  end
end
