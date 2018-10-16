module Dry
  class AnnotationImpl < BasicObject
    def method_missing(name, *args, &λ)
      ::Kernel.puts([name, *args].inspect)
      ->(*params) { ::Kernel.puts([name, params]) }
      self
    end

    def self.spec(*args)
      puts "Spec: #{args.inspect}"
    end
  end

  module Annotation
    def self.included(base)
      base.instance_variable_set(:@annotations, AnnotationImpl.new)
      base.instance_variable_set(:@spec, AnnotationImpl.method(:spec).to_proc)

      base.instance_eval do
        def const_missing(name)
          @annotations.public_send(name)
        end
      end
    end
  end
end
