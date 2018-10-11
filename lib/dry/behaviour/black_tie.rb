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
      BlackTie.protocols[self][name] = params
    end

    DELEGATE_METHOD = lambda do |klazz, (source, target)|
      klazz.class_eval do
        define_method(source, &Dry::DEFINE_METHOD.curry[target])
      end
    end

    POSTPONE_EXTEND = lambda do |target, protocol|
      TracePoint.new(:end) do |tp|
        if tp.self == protocol
          target.extend protocol
          tp.disable
        end
      end.enable
    end

    NORMALIZE_KEYS = lambda do |protocol|
      BlackTie.protocols[protocol].keys.reject { |k| k.to_s =~ /\A__.*__\z/ }
    end

    IMPLICIT_DELEGATE_DEPRECATION =
      "\n⚠️  DEPRECATED →  Implicit delegation to the target class will be removed in 1.0\n" \
      "  ⮩   due to the lack of the explicit implementation of %s#%s for %s\n" \
      "  ⮩   it will be delegated to the target class itself.\n" \
      "  ⮩  Consider using explicit `delegate:' declaration in `defimpl' or\n" \
      "  ⮩   use `implicit_inheritance: true' parameter in protocol definition.".freeze

    def defimpl(protocol = nil, target: nil, delegate: [], map: {}, &λ)
      raise if target.nil? || !block_given? && delegate.empty? && map.empty?

      mds = normalize_map_delegates(delegate, map)

      Module.new do
        mds.each(&DELEGATE_METHOD.curry[singleton_class])
        singleton_class.class_eval(&λ) if block_given? # block takes precedence
      end.tap do |mod|
        protocol ? mod.extend(protocol) : POSTPONE_EXTEND.(mod, protocol = self)

        mod.methods(false).tap do |meths|
          (NORMALIZE_KEYS.(protocol) - meths).each_with_object(meths) do |m, acc|
            if BlackTie.protocols[protocol][:__implicit_inheritance__]
              mod.singleton_class.class_eval do
                define_method m do |*args, &λ|
                  super(*args, &λ)
                end
              end
            else
              BlackTie.Logger.warn(
                IMPLICIT_DELEGATE_DEPRECATION % [protocol.inspect, m, target]
              )
              DELEGATE_METHOD.(mod.singleton_class, [m] * 2)
            end
            acc << m
          end
        end.each do |m|
          target = [target] unless target.is_a?(Array)
          target.each do |tgt|
            BlackTie.implementations[protocol][tgt][m] = mod.method(m).to_proc
          end
        end
      end
    end
    module_function :defimpl

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
