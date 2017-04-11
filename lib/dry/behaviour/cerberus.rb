module Dry
  module Cerberus
    POSTPONE_FIX_CLAUSES = lambda do |guarded|
      TracePoint.new(:end) do |tp|
        if tp.self == guarded
          H.umbrellas(guarded)
          tp.disable
        end
      end.enable
    end

    @adding_alias = false

    def guarded_methods
      @guarded_methods ||= {}
    end

    # [[:req, :p], [:opt, :po], [:rest, :a], [:key, :when], [:keyrest, :b], [:block, :cb]]
    def method_added(name)
      return if @adding_alias

      m = instance_method(name)
      key = m.parameters.any? { |(k, v)| k == :key && v == :when } ? H.extract_when(m) : m.arity
      key = case key
            when String then instance_eval(key)
            when -Float::INFINITY...0 then nil
            else key
            end
      (guarded_methods[name] ||= {})[key] = m

      @adding_alias = true
      alias_name = H.alias_name(m, guarded_methods[name].size.pred)
      alias_method alias_name, name
      private alias_name
      @adding_alias = false
    end

    module H
      CONCAT = '_★_'.freeze

      module_function

      def extract_when(m)
        file, line = m.source_location
        raise ::Dry::Guards::NotGuardable.new(m, :nil) if file.nil?

        File.readlines(file)[line - 1..-1].join(' ')[/(?<=when:).*/].tap do |guard|
          raise ::Dry::Guards::NotGuardable.new(m, :when_is_nil) if guard.nil?
          clause = parse_hash guard
          raise ::Dry::Guards::NotGuardable.new(m, :when_not_hash) unless clause.is_a?(String)
          guard.replace clause
        end
      rescue Errno::ENOENT => e
        raise ::Dry::Guards::NotGuardable.new(m, e)
      end

      def alias_name(m, idx)
        :"#{m && m.name}#{CONCAT}#{idx}"
      end

      def parse_hash(input)
        input.each_codepoint
             .drop_while { |cp| cp != 123 }
             .each_with_object(['', 0]) do |cp, acc|
          case cp
          when 123 then acc[-1] = acc.last.succ
          when 125 then acc[-1] = acc.last.pred
          end
          acc.first << cp
          break acc.first if acc.last.zero?
        end
      end

      def umbrellas(guarded)
        guarded.guarded_methods.reject! do |_, hash|
          next unless hash.size == 1 && hash.keys.first.is_a?(Integer)
          guarded.send :remove_method, alias_name(hash.values.first, 0)
        end
        # guarded.guarded_methods.each(&H.method(:umbrella).to_proc.curry[guarded])
        guarded.guarded_methods.each do |name, clauses|
          H.umbrella(guarded, name, clauses)
        end
      end

      def umbrella(guarded, name, clauses)
        guarded.prepend(Module.new do
          define_method name do |*args, **params, &cb|
            found = clauses.each_with_index.detect do |(hash, m), idx|
              next if m.arity >= 0 && m.arity != args.size
              break [[hash, m], idx] if case hash
                                        when NilClass then m.arity < 0
                                        when Integer then hash == args.size
                                        end
              next if hash.nil?
              hash.all? do |param, condition|
                idx = m.parameters.index { |_type, var| var == param }
                # rubocop:disable Style/CaseEquality
                # rubocop:disable Style/RescueModifier
                idx && condition === args[idx] rescue false # FIXME: more accurate
                # rubocop:enable Style/RescueModifier
                # rubocop:enable Style/CaseEquality
              end
            end
            raise ::Dry::Guards::NotMatched.new(*args, **params, &cb) unless found
            ::Dry::DEFINE_METHOD.(H.alias_name(found.first.last, found.last), self, *args, **params, &cb)
          end
        end)
      end
    end
    private_constant :H
  end
end
