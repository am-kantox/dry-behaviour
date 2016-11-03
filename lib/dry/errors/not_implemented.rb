module Dry
  module Protocol
    class NotImplemented < StandardError
      def initialize(type, proto, impl)
        super case type
              when :protocol
                "Protocol “#{proto}” is not implemented for “#{impl}”."
              when :method
                "Protocol “#{proto}” does not declare method “#{impl}”."
              else
                "Protocol “#{proto}” is invalid."
              end
      end
    end
  end
end
