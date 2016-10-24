require 'dry/behaviour/version'
require 'dry/behaviour/black_tie'

module Dry
  module Protocol
    def self.included(base)
      base.singleton_class.prepend(Dry::BlackTie)
    end
  end
end
