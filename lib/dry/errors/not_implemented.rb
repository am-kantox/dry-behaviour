module Dry
  module Protocol
    class NotImplemented < StandardError
      attr_reader :proto, :details

      def initialize(type, proto, **details)
        @proto, @details = proto, details

        @details[:message] =
          case type
          when :protocol
            "Protocol “#{@proto}” is not implemented for “#{@details[:receiver].class}”."
          when :method
            "Protocol “#{@proto}” does not declare method “#{@details[:method]}”."
          when :nested
            "Protocol “#{@proto}” failed to invoke the implementation for\n" \
            " ⮩    “#{@details[:receiver].class}##{@details[:method]}”.\n" \
            " ⮩  Caused by “#{cause.class}” with a message\n" \
            " ⮩    “#{cause.message}”\n" \
            " ⮩  Rescue this exception and inspect `NotImplemented#cause' for details."
          else
            "Protocol “#{proto}” is invalid."
          end

        super(@details[:message])

        if @details[:cause]
          set_backtrace(
            @details[:cause].backtrace.reject do |line| # FIXME drop_while ??
              line =~ %r[dry-behaviour/lib/dry/behaviour]
            end
          )
        end
      end

      def cause
        @details[:cause] ||= super
      end
    end
  end
end
