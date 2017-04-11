module Dry
  module Guards
    class NotGuardable < StandardError
      def initialize(method, cause)
        reason = case cause
                 when :nil then 'source location is inavailable'
                 when Errno::ENOENT then "source file could not be read [#{cause.message}]"
                 when :when_is_nil then 'when clause is missing'
                 when :when_not_hash then 'when clause is not a hash'
                 end
        super "Can’t guard method “#{method.inspect}” (#{reason}.)"
      end
    end
  end
end
