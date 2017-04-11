module Dry
  module Guards
    class NotMatched < StandardError
      def initialize(*args, **params, &cb)
        super "Clause not matched. Parameters supplied: [args: #{args.inspect}, params: #{params.inspect}, cb: #{cb.inspect}]"
      end
    end
  end
end
