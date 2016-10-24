module Dry
  # rubocop:disable Style/VariableName
  # rubocop:disable Style/AsciiIdentifiers
  # rubocop:disable Style/MultilineBlockChain
  # rubocop:disable Style/EmptyCaseCondiiton
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

      BlackTie.protocols[self].each do |method, *_| # FIXME CHECK PARAMS CORRESPONDENCE HERE
        # receiver, *args = *args
        singleton_class.send :define_method, method do |receiver, *args|
          receiver.class.ancestors.lazy.map do |c|
            BlackTie.implementations[self].fetch(c, nil)
          end.reject(&:nil?).first[method].(receiver, *args)
        end
      end
    end

    def defmethod(name, *params)
      BlackTie.protocols[self][name] = params
    end

    def defimpl(protocol = nil, target: nil, delegate: [], map: {})
      raise if target.nil?
      raise if !block_given? && delegate.empty? && map.empty?

      mds = normalize_map_delegates(delegate, map)
      Module.new do
        mds.each do |k, v|
          singleton_class.class_eval do
            define_method k do |this, *args, **params, &λ|
              case
              when !args.empty? && !params.empty?
                this.send(v, *args, **params, &λ)
              when !args.empty? then this.send(v, *args, &λ)
              when !params.empty? then this.send(v, **params, &λ)
              else this.send(v, &λ)
              end
            end
          end
        end
        singleton_class.class_eval(&Proc.new) if block_given? # block takes precedence
      end.tap do |mod|
        mod.methods(false).each do |m|
          BlackTie.implementations[protocol || self][target][m] = mod.method(m).to_proc
        end
      end
    end

    private

    def normalize_map_delegates(delegate, map)
      md = [*delegate].to_a | [*map].to_a

      λ_delegate = ->(e) { e.is_a?(Symbol) || e.is_a?(String) ? [e.to_sym, e.to_sym] : nil }
      λ_map = ->(e) { e.is_a?(Array) && e.size == 2 ? [e.first.to_sym, e.last.to_sym] : nil }
      (md.map(&λ_delegate) | md.map(&λ_map)).compact.to_h
    end
  end
  # rubocop:enable Style/EmptyCaseCondiiton
  # rubocop:enable Style/MultilineBlockChain
  # rubocop:enable Style/AsciiIdentifiers
  # rubocop:enable Style/VariableName
end
