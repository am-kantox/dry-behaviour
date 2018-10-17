module Dry
  class AnnotationImpl < BasicObject
    def initialize
      @spec = []
      @specs = []
      @types = {args: [], result: []}
    end

    def 📝 &λ
      return @spec if λ.nil?
      (yield @spec).tap { @spec.clear }
    end

    def 📝📝
      @specs
    end

    def 📇
      @types
    end

    def to_s
      @specs.reject do |type|
        %i[args result].all? { |key| type[key].empty? }
      end.map do |type|
        "@spec[" <<
          type.
            values.
            map { |args| args.map { |args| "(#{args.join(' | ')})" }.join(', ') }.
            join(' :: ') << "]"
      end.join(' || ')
    end

    def inspect
      @specs.reject do |type|
        %i[args result].all? { |key| type[key].empty? }
      end.inspect
    end

    def call(*)
      @types[:result] << @types[:args].pop
      self
    end

    def |(_)
      @types[:args].push(
        2.times.map { @types[:args].pop }.rotate.reduce(&:concat)
      )
      self
    end

    def 🖊️(name, *args, &λ)
      @types[:args] << [args.empty? ? name : [name, args, λ]]
      self
    end
  end

  module Annotation
    def self.included(base)
      annotations = AnnotationImpl.new
      base.instance_variable_set(:@annotations, annotations)
      base.instance_variable_set(:@spec, ->(*args) {
        impl = args.first
        last_spec = impl.📇.map { |k, v| [k, v.dup] }.to_h

        # TODO WARN IF SPEC IS EMPTY
        %i[args result].each do |key|
          last_spec[key] << %i[any] if last_spec[key].empty?
        end

        base.instance_variable_get(:@annotations).📝📝 << last_spec
        base.instance_variable_get(:@annotations).📝.replace([last_spec])

        impl.📝📝 << last_spec
        impl.📇.each { |k, v| v.clear }
      })

      base.instance_eval do
        def method_missing(name, *args, &λ)
          @annotations.__send__(:🖊️, name, *args, &λ)
        end
      end
    end
  end
end
