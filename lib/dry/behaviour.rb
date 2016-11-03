require 'dry/behaviour/version'
require 'dry/errors/not_implemented'
require 'dry/behaviour/black_tie'

module Dry
  module Protocol
    def self.included(base)
      base.singleton_class.prepend(Dry::BlackTie)
    end

    class << self
      # rubocop:disable Style/AsciiIdentifiers
      def defimpl(protocol = nil, target: nil, delegate: [], map: {}, &λ)
        Dry::BlackTie.defimpl(protocol, target: target, delegate: delegate, map: map, &λ)
      end
      # rubocop:enable Style/AsciiIdentifiers
    end
  end
end
