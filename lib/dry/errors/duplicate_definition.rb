module Dry
  module Protocol
    class DuplicateDefinition < StandardError
      def initialize(suspect)
        super "Duplicate definition of “#{suspect.inspect}” detected."
      end
    end
  end
end
