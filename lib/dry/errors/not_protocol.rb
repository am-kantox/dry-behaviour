module Dry
  module Protocol
    class NotProtocol < StandardError
      def initialize(suspect)
        super "“#{suspect.inspect}” is not a protocol."
      end
    end
  end
end
