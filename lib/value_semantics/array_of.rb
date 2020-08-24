module ValueSemantics
  #
  # Validator that matches arrays if each element matches a given subvalidator
  #
  class ArrayOf
    attr_reader :element_validator

    def initialize(element_validator)
      @element_validator = element_validator
      freeze
    end

    # @return [Boolean]
    def ===(value)
      Array === value && value.all? { |element| element_validator === element }
    end
  end
end
