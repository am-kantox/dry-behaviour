module Dry
  class AnnotationImpl < BasicObject
    def initialize
      @specs = []
      @types = {args: [], result: []}
    end

    def __types__
      @types
    end

    def __specs__
      @specs
    end

    def to_s
      @specs.reject do |type|
        %i[args result].all? { |key| type[key].empty? }
      end.map do |type|
        %i[args result].each do |key|
          type[key] << %i[Any] if type[key].empty?
        end

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

    def method_missing(name, *args, &λ)
      name.to_s[0][/[A-Z]/] ? (@types[:args] << [name]) : super
      self
    end
  end

  module Annotation
    def self.included(base)
      annotations = AnnotationImpl.new
      base.instance_variable_set(:@annotations, annotations)
      base.instance_variable_set(:@spec, ->(*args) {
        impl = args.first

        base.instance_variable_get(:@annotations).__specs__ <<
          impl.__types__.map { |k, v| [k, v.dup] }.to_h

        impl.__specs__ << impl.__types__
        impl.__types__.each { |k, v| v.clear }
      })

      base.instance_eval do
        def const_missing(name)
          @annotations.__send__(name)
        end
      end
    end
  end
end
