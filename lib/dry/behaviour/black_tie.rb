module Dry
  # rubocop:disable Style/AsciiIdentifiers
  # rubocop:disable Style/MultilineBlockChain
  # rubocop:disable Style/EmptyCaseCondition
  # rubocop:disable Metrics/PerceivedComplexity
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/AbcSize
  module BlackTie
    class << self
      def protocols
        @protocols ||= Hash.new { |h, k| h[k] = h.dup.clear }
      end

      def implementations
        @implementations ||= Hash.new { |h, k| h[k] = h.dup.clear }
      end
    end

    def defprotocol
      raise if BlackTie.protocols.key?(self) # DUPLICATE DEF
      raise unless block_given?

      ims = instance_methods(false)
      class_eval(&Proc.new)
      (instance_methods(false) - ims).each { |m| class_eval { module_function m } }

      BlackTie.protocols[self].each do |method, *_| # FIXME: CHECK PARAMS CORRESPONDENCE HERE
        # receiver, *args = *args
        singleton_class.send :define_method, method do |receiver, *args|
          receiver.class.ancestors.lazy.map do |c|
            BlackTie.implementations[self].fetch(c, nil)
          end.reject(&:nil?).first[method].(*args.unshift(receiver))
        end
      end
    end

    def defmethod(name, *params)
      BlackTie.protocols[self][name] = params
    end

    DELEGATE_METHOD = lambda do |klazz, (source, target)|
      klazz.class_eval do
        define_method source do |this, *args, **params, &λ|
          case
          when !args.empty? && !params.empty? then this.send(target, *args, **params, &λ)
          when !args.empty? then this.send(target, *args, &λ)
          when !params.empty? then this.send(target, **params, &λ)
          else this.send(target, &λ)
          end
        end
      end
    end

    def defimpl(protocol = nil, target: nil, delegate: [], map: {})
      raise if target.nil? || !block_given? && delegate.empty? && map.empty?

      mds = normalize_map_delegates(delegate, map)
      Module.new do
        mds.each(&DELEGATE_METHOD.curry[singleton_class])
        singleton_class.class_eval(&Proc.new) if block_given? # block takes precedence
      end.tap do |mod|
        mod.methods(false).tap do |meths|
          (BlackTie.protocols[protocol || self].keys - meths).each_with_object(meths) do |m, acc|
            safe_logger.warn("Implicit delegate #{(protocol || self).inspect}##{m} to #{target}")
            DELEGATE_METHOD.(mod.singleton_class, [m] * 2)
            acc << m
          end
        end.each do |m|
          BlackTie.implementations[protocol || self][target][m] = mod.method(m).to_proc
        end
      end
    end
    module_function :defimpl

    private

    def safe_logger
      if Kernel.const_defined?('::Rails')
        Rails.logger
      else
        require 'logger'
        Logger.new($stdout)
      end
    end

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
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity
  # rubocop:enable Style/EmptyCaseCondition
  # rubocop:enable Style/MultilineBlockChain
  # rubocop:enable Style/AsciiIdentifiers
end
