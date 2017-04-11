module Dry
  module Guards
    class NotGuardable < StandardError
      def initialize(method, cause)
        reason = case cause
                 when :nil then 'source location is inavailable'
                 when Errno::ENOENT then "source file could not be read [#{cause.message}]"
                 when :when then 'when clause is missing'
                 end
        super "Can’t guard method “#{method.inspect}” (#{reason}.)"
      end
    end
  end
end
