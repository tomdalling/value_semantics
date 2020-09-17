module ValueSemantics
  #
  # Builds a {Recipe} via DSL methods
  #
  # DSL blocks are <code>instance_eval</code>d against an object of this class.
  #
  # @see Recipe
  # @see ValueSemantics.for_attributes
  #
  class DSL
    # TODO: this should maybe inherit from BasicObject so that method_missing
    # doesn't find methods on Kernel. This might have undesirable consequences
    # tho, and we will probably need to do some const_missing stuff to get it
    # working smoothly. Evaluate the feasability of this before the next major
    # version bump, because it would be a backwards-incompatible change.

    #
    # Builds a {Recipe} from a DSL block
    #
    # @yield to the block containing the DSL
    # @return [Recipe]
    def self.run(&block)
      dsl = new
      dsl.instance_eval(&block)
      Recipe.new(attributes: dsl.__attributes.freeze)
    end

    attr_reader :__attributes

    def initialize
      @__attributes = []
    end

    def Bool
      Bool
    end

    def Either(*subvalidators)
      Either.new(subvalidators)
    end

    def Anything
      Anything
    end

    def ArrayOf(element_validator)
      ArrayOf.new(element_validator)
    end

    def HashOf(key_validator_to_value_validator)
      unless key_validator_to_value_validator.size.equal?(1)
        raise ArgumentError, "HashOf() takes a hash with one key and one value"
      end

      HashOf.new(
        key_validator_to_value_validator.keys.first,
        key_validator_to_value_validator.values.first,
      )
    end

    def RangeOf(subvalidator)
      RangeOf.new(subvalidator)
    end

    def ArrayCoercer(element_coercer)
      ArrayCoercer.new(element_coercer)
    end

    IDENTITY_COERCER = :itself.to_proc
    def HashCoercer(keys: IDENTITY_COERCER, values: IDENTITY_COERCER)
      HashCoercer.new(key_coercer: keys, value_coercer: values)
    end

    #
    # Defines one attribute.
    #
    # This is the method that gets called under the hood, when defining
    # attributes the typical +#method_missing+ way.
    #
    # You can use this method directly if your attribute name results in invalid
    # Ruby syntax. For example, if you want an attribute named +then+, you
    # can do:
    #
    #     include ValueSemantics.for_attributes {
    #       # Does not work:
    #       then String, default: "whatever"
    #       #=> SyntaxError: syntax error, unexpected `then'
    #
    #       # Works:
    #       def_attr :then, String, default: "whatever"
    #     }
    #
    #
    def def_attr(*args, **kwargs)
      __attributes << Attribute.define(*args, **kwargs)
      nil
    end

    def method_missing(name, *args, **kwargs)
      if respond_to_missing?(name)
        def_attr(name, *args, **kwargs)
      else
        super
      end
    end

    def respond_to_missing?(method_name, _include_private=nil)
      first_letter = method_name.to_s.each_char.first
      first_letter.eql?(first_letter.downcase)
    end
  end
end
