module Dry
  module Cerberus
    POSTPONE_FIX_CLAUSES = lambda do |guarded|
      TracePoint.new(:end) do |tp|
        if tp.self == guarded
          puts guarded_methods.inspect
          tp.disable
        end
      end.enable
    end

    def guarded_methods
      @guarded_methods ||= {}
    end
    def method_added(name)
      puts "MA #{name} :: #{instance_method(name).arity} :: #{instance_method(name).parameters}"
      (guarded_methods[name] ||= {})
    end
  end
end
