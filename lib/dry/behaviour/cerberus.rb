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

    def guarded_methods
      @guarded_methods ||= {}
    end

    # [[:req, :p], [:opt, :po], [:rest, :a], [:key, :when], [:keyrest, :b], [:block, :cb]]
    def method_added(name)
      m = instance_method(name)
      key = m.parameters.any? { |(k, v)| k == :key && v == :when } ? H.extract_when(m) : nil
      (guarded_methods[name] ||= {})[key] = m
    end

    module H
      module_function

      def extract_when(m)
        file, line = m.source_location
        raise ::Dry::Guards::NotGuardable.new(m, :nil) if file.nil?

        # FIXME: more careful grep
        File.readlines(file)[line - 1..-1].join(' ')[/(?<=when:).*?}/].tap do |guard|
          raise ::Dry::Guards::NotGuardable.new(m, :when) if guard.nil?
        end
      rescue Errno::ENOENT => e
        raise ::Dry::Guards::NotGuardable.new(m, e)
      end

      def umbrellas(guarded)
        guarded.guarded_methods.each(&H.method(:umbrella))
      end

      def umbrella(name, clauses)
        puts "★ #{name} ⇒ #{clauses}"
      end
    end
    private_constant :H
  end
end
