module Dry
  module BlackTie
    class << self
      def protocols
        @protocols ||= Hash.new { |h, k| h[k] = h.dup.clear }
      end

      def implementations
        @implementations ||= Hash.new { |h, k| h[k] = h.dup.clear }
      end
    end

    def defprotocol(delegate: [])
      raise if BlackTie.protocols.key?(self) # DUPLICATE DEF
      raise unless block_given? || !delegate.empty?
      # FIXME IMPLEMENT DELEGATES!
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

    def defmethod name, *params
      BlackTie.protocols[self][name] = params
    end

    def defimpl protocol = nil, **params
      raise unless block_given?
      raise if params[:for].nil?

      Module.new { singleton_class.class_eval(&Proc.new) }.tap do |mod|
        mod.methods(false).each do |m|
          BlackTie.implementations[protocol || self][params[:for]][m] = mod.method(m).to_proc
        end
      end
    end
  end
end
