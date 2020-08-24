module ValueSemantics
  #
  # All the class methods available on ValueSemantics classes
  #
  # When a ValueSemantics module is included into a class,
  # the class is extended by this module.
  #
  module ClassMethods
    #
    # @return [Recipe] the recipe used to build the ValueSemantics module that
    #                  was included into this class.
    #
    def value_semantics
      if block_given?
        # caller is trying to use the monkey-patched Class method
        raise "`#{self}` has already included ValueSemantics"
      end

      self::VALUE_SEMANTICS_RECIPE__
    end

    #
    # A coercer object for the value class
    #
    # This is mostly useful when nesting value objects inside each other.
    #
    # @return [#call] A callable object that can be used as a coercer
    # @see ValueObjectCoercer
    #
    def coercer
      ValueObjectCoercer.new(self)
    end
  end
end
