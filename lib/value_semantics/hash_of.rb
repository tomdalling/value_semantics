module ValueSemantics
  #
  # Validator that matches +Hash+es with homogeneous keys and values
  #
  class HashOf
    attr_reader :key_validator, :value_validator

    def initialize(key_validator, value_validator)
      @key_validator, @value_validator = key_validator, value_validator
      freeze
    end

    # @return [Boolean]
    def ===(value)
      Hash === value && value.all? do |key, value|
        key_validator === key && value_validator === value
      end
    end
  end
end
