module Dry
  module Behaviour
    module Protocol
      class << self
        def protocols
          @protocols ||= {}
        end
        def implementations
          @implementations ||= {}
        end
        def mutex
          @mutex ||= Mutex.new
        end
        def current
          @current ||= []
        end
      end

      def defprotocol(name, delegate: [])
        name = name.to_sym

        raise if Protocol.protocols[name] # DUPLICATE DEF
        raise unless block_given? || !delegate.empty?
        # FIXME IMPLEMENT DELEGATES!
        raise unless block_given?
        λ = Proc.new

        Protocol.mutex.synchronize do
          begin
            Protocol.current.push name
            λ.()
          ensure
            Protocol.current.pop
          end
        end

        const_set(name.to_s.gsub(/(?:\A|_)(\w)/, &:upcase).delete('_'), Module.new do
          Protocol.protocols[name].each do |method, _| # FIXME CHECK PARAMS CORRESPONDENCE HERE
            # receiver, *args = *args
            self.class.send :define_method, method do |receiver, *args|
              Protocol.implementations[name].detect { |c, _| receiver.is_a?(c) }.last[method].(receiver, *args)
            end
          end
        end)
      end

      def defmethod name, *params
        raise if Protocol.current.empty? # incorrect invocation
        (Protocol.protocols[Protocol.current.first] ||= {})[name] = params
      end

      # defimpl Adder, for: Integer do
      #   add { |other| o + other }
      # end
      def defimpl protocol, **params
        raise unless block_given?
        raise if params[:for].nil?
        impl = Proc.new.()

        (Protocol.implementations[protocol] ||= {})[params[:for]] ||= impl
      end
    end
  end
end

Module.prepend(Dry::Behaviour::Protocol)
