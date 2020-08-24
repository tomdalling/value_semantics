module ValueSemantics
  #
  # Validator that matches if any of the given subvalidators matches
  #
  class Either
    attr_reader :subvalidators

    def initialize(subvalidators)
      @subvalidators = subvalidators
      freeze
    end

    # @return [Boolean]
    def ===(value)
      subvalidators.any? { |sv| sv === value }
    end
  end
end
