module ValueSemantics
  #
  # Validator that matches any and all values
  #
  module Anything
    # @return [true]
    def self.===(_)
      true
    end
  end
end
