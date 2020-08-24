module ValueSemantics
  #
  # Validator that only matches `true` and `false`
  #
  module Bool
    # @return [Boolean]
    def self.===(value)
      true.equal?(value) || false.equal?(value)
    end
  end
end
