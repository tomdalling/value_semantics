module ValueSemantics
  class HashCoercer
    attr_reader :key_coercer, :value_coercer

    def initialize(key_coercer:, value_coercer:)
      @key_coercer, @value_coercer = key_coercer, value_coercer
      freeze
    end

    def call(obj)
      hash = coerce_to_hash(obj)
      return obj unless hash

      {}.tap do |result|
        hash.each do |key, value|
          r_key = key_coercer.(key)
          r_value = value_coercer.(value)
          result[r_key] = r_value
        end
      end
    end

    private

      def coerce_to_hash(obj)
        return nil unless obj.respond_to?(:to_h)
        obj.to_h
      end
  end
end
