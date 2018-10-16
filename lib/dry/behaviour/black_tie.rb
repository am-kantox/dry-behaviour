module Dry
  # rubocop:disable Style/MultilineBlockChain
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Style/MethodName
  module BlackTie
    class << self
      def protocols
        @protocols ||= Hash.new { |h, k| h[k] = h.dup.clear }
      end

      def implementations
        @implementations ||= Hash.new { |h, k| h[k] = h.dup.clear }
      end
    end

    def defprotocol(implicit_inheritance: false, &λ)
      raise ::Dry::Protocol::DuplicateDefinition.new(self) if BlackTie.protocols.key?(self)
      raise ::Dry::Protocol::MalformedDefinition.new(self) unless block_given?

      BlackTie.protocols[self][:__implicit_inheritance__] = !!implicit_inheritance

      ims = instance_methods(false)
      class_eval(&λ)
      (instance_methods(false) - ims).each { |m| class_eval { module_function m } }

      singleton_class.send :define_method, :method_missing do |method, *_args|
        raise Dry::Protocol::NotImplemented.new(
          :method, inspect, method: method, self: self
        )
      end

      singleton_class.send :define_method, :implementation_for do |receiver|
        receiver.class.ancestors.lazy.map do |c|
          BlackTie.implementations[self].fetch(c, nil)
        end.reject(&:nil?).first
      end

      BlackTie.protocols[self].each do |method, *_| # FIXME: CHECK ARITY HERE
        singleton_class.send :define_method, method do |receiver = nil, *args|
          impl = implementation_for(receiver)
          raise Dry::Protocol::NotImplemented.new(
            :protocol, inspect,
            method: method, receiver: receiver, args: args, self: self
          ) unless impl
          begin
            impl[method].(*args.unshift(receiver))
          rescue => e
            raise Dry::Protocol::NotImplemented.new(
                :nested, inspect,
                cause: e,
                method: method, receiver: receiver, args: args, impl: impl, self: self
              )
          end
        end
      end

      singleton_class.send :define_method, :respond_to? do |method|
        NORMALIZE_KEYS.(self).include? method
      end
    end

    def defmethod(name, *params)
      if params.size.zero? || params.first.is_a?(Array) && params.first.last != :req
        BlackTie.Logger.warn(IMPLICIT_RECEIVER_DECLARATION % [Dry::BlackTie.proto_caller, self.inspect, name])
        params.unshift(:this)
      end
      params =
        params.map do |p, type|
          if type && !PARAM_TYPES.include?(type)
            BlackTie.Logger.warn(UNKNOWN_TYPE_DECLARATION % [Dry::BlackTie.proto_caller, type, self.inspect, name])
            type = nil
          end
          [type || PARAM_TYPES.include?(p) ? p : :req, p]
        end
      BlackTie.protocols[self][name] = params
    end

    def defimpl(protocol = nil, target: nil, delegate: [], map: {}, &λ)
      raise NotImplemented.new(:orphan, protocol || self) if target.nil?
      raise NotImplemented.new(:void, protocol || self, target: target) if
        !block_given? && delegate.empty? && map.empty? &&
          !BlackTie.protocols[protocol || self][:__implicit_inheritance__]

      mds = normalize_map_delegates(delegate, map)

      Module.new do
        mds.each(&DELEGATE_METHOD.curry[singleton_class])
        singleton_class.class_eval(&λ) if block_given? # block takes precedence
      end.tap do |mod|
        if protocol
          mod.extend(protocol)
          BlackTie.Logger.info(PROTOCOL_CONSOLIDATED % [protocol.inspect, target, :inplace])
        else
          POSTPONE_EXTEND.(mod, protocol = self, target)
        end

        mod.methods(false).tap do |meths|
          (NORMALIZE_KEYS.(protocol) - meths).each_with_object(meths) do |m, acc|
            if BlackTie.protocols[protocol][:__implicit_inheritance__]
              mod.singleton_class.class_eval do
                define_method m do |this, *♿_args, &♿_λ|
                  super(this, *♿_args, &♿_λ)
                end
              end
            else
              BlackTie.Logger.warn(
                IMPLICIT_DELEGATE_DEPRECATION % [Dry::BlackTie.proto_caller, protocol.inspect, m, target]
              )
              DELEGATE_METHOD.(mod.singleton_class, [m] * 2)
            end
            acc << m
          end
        end.each do |m|
          target = [target] unless target.is_a?(Array)
          target.each do |tgt|
            ok =
              [
                BlackTie.protocols[protocol][m],
                mod.method(m).parameters.reject { |_, v| v.to_s[/\A♿_/] }
              ].map(&:first).reduce(:==)

            # TODO[1.0] raise NotImplemented(:arity)
            BlackTie.Logger.warn(
              WRONG_PARAMETER_DECLARATION % [Dry::BlackTie.proto_caller, protocol.inspect, m, target, BlackTie.protocols[protocol][m].map(&:first)]
            ) unless ok

            BlackTie.implementations[protocol][tgt][m] = mod.method(m).to_proc
          end
        end
      end
    end
    module_function :defimpl

    PARAM_TYPES = %i[req opt rest keyrest block]

    DELEGATE_METHOD = lambda do |klazz, (source, target)|
      klazz.class_eval do
        define_method(source, &Dry::DEFINE_METHOD.curry[target])
      end
    end

    POSTPONE_EXTEND = lambda do |mod, protocol, target|
      TracePoint.new(:end) do |tp|
        if tp.self == protocol
          mod.extend protocol
          tp.disable
          BlackTie.Logger.info(PROTOCOL_CONSOLIDATED % [protocol.inspect, target, :postponed])
        end
      end.enable
    end

    NORMALIZE_KEYS = lambda do |protocol|
      BlackTie.protocols[protocol].keys.reject { |k| k.to_s =~ /\A__.*__\z/ }
    end

    def self.proto_caller
      caller.drop_while do |line|
        line =~ %r[dry-behaviour/lib/dry/behaviour]
      end.first
    end

    IMPLICIT_DELEGATE_DEPRECATION =
      "\n🚨️  DEPRECATED →  %s\n" \
      "  ⮩  Implicit delegation to the target class will be removed in 1.0\n" \
      "  ⮩   due to the lack of the explicit implementation of %s#%s for %s\n" \
      "  ⮩   it will be delegated to the target class itself.\n" \
      "  ⮩  Consider using explicit `delegate:' declaration in `defimpl' or\n" \
      "  ⮩   use `implicit_inheritance: true' parameter in protocol definition.".freeze

    IMPLICIT_RECEIVER_DECLARATION =
      "\n⚠️  TOO IMPLICIT →  %s\n" \
      "  ⮩  Implicit declaration of `this' parameter in `defmethod'.\n" \
      "  ⮩   Whilst it’s allowed, we strongly encourage to explicitly declare it\n" \
      "  ⮩   in call to %s#defmethod(%s).".freeze

    UNKNOWN_TYPE_DECLARATION =
      "\n⚠️  UNKNOWN TYPE →  %s\n" \
      "  ⮩  Unknown parameter type [%s] in call to %s#defmethod(%s).\n" \
      "  ⮩   Is it a typo? Omit the type for `:req' or pass one of allowed types:\n" \
      "  ⮩   #{PARAM_TYPES.inspect}".freeze

    WRONG_PARAMETER_DECLARATION =
      "\n🚨️  DEPRECATED →  %s\n" \
      "  ⮩  Wrong parameters declaration will be removed in 1.0\n" \
      "  ⮩   %s#%s was implemented for %s with unexpected parameters.\n" \
      "  ⮩  Consider implementing interfaces exactly as they were declared.\n" \
      "  ⮩   Expected: %s".freeze

    PROTOCOL_CONSOLIDATED =
      "ℹ️ Protocol %s was consolidated for %s [%s].".freeze

    def self.Logger
      @logger ||= if Kernel.const_defined?('::Rails')
                    Rails.logger
                  else
                    require 'logger'
                    Logger.new($stdout)
                  end
    end

    private

    def normalize_map_delegates(delegate, map)
      [*delegate, *map].map do |e|
        case e
        when Symbol, String then [e.to_sym] * 2
        when Array then e.map(&:to_sym) if e.size == 2
        end
      end.compact
    end
    module_function :normalize_map_delegates
  end
  # rubocop:enable Style/MethodName
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Style/MultilineBlockChain
end
