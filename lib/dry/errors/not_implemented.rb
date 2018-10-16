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
          when :arity
            "Attempt to implement “#{@proto}#@details[:method]}”\n" \
            " ⮩    with a wrong arity for “#{@details[:target]}”.\n" \
            " ⮩  Expected parameters types:\n" \
            " ⮩    “#{@details[:expected]}”\n" \
            " ⮩  Provided parameters types:\n" \
            " ⮩    “#{@details[:provided]}”\n" \
            " ⮩  Please consider providing a proper implementation."
          when :orphan
            "Implementation of “#{@proto}” for void target makes no sense.\n" \
            " ⮩  Please specify `target:' argument in call to `defimpl'."
          when :void
            "Implementation of “#{@proto}” for #{@details[:target]} is void.\n" \
            " ⮩  Please either use a block, or delegate method(s) to the target,\n" \
            " ⮩    or use `implicit_inheritance: true' in call to `defprotocol'."
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
