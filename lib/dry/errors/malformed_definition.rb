module Dry
  module Protocol
    class MalformedDefinition < StandardError
      def initialize(suspect)
        super "Malformed definition of “#{suspect.inspect}”. Block required."
      end
    end
  end
end
