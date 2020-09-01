module ValueSemantics
  #
  # Represents a single attribute of a value class
  #
  class Attribute
    NOT_SPECIFIED = Object.new.freeze
    NO_DEFAULT_GENERATOR = lambda do
      raise NoDefaultValue, "Attribute does not have a default value"
    end

    attr_reader :name, :validator, :coercer, :default_generator, :instance_variable

    def initialize(
      name:,
      default_generator: NO_DEFAULT_GENERATOR,
      validator: Anything,
      coercer: nil
    )
      @name = name.to_sym
      @default_generator = default_generator
      @validator = validator
      @coercer = coercer
      @instance_variable = '@' + name.to_s.chomp('!').chomp('?')
      freeze
    end

    def self.define(
      name,
      validator=Anything,
      default: NOT_SPECIFIED,
      default_generator: nil,
      coerce: nil
    )
      # TODO: change how defaults are specified:
      #
      #  - default: either a value, or a callable
      #  - default_value: always a value
      #  - default_generator: always a callable
      #
      # This would not be a backwards compatible change.
      generator = begin
        if default_generator && !default.equal?(NOT_SPECIFIED)
          raise ArgumentError, "Attribute `#{name}` can not have both a `:default` and a `:default_generator`"
        elsif default_generator
          default_generator
        elsif !default.equal?(NOT_SPECIFIED)
          ->{ default }
        else
          NO_DEFAULT_GENERATOR
        end
      end

      new(
        name: name,
        validator: validator,
        default_generator: generator,
        coercer: coerce,
      )
    end

    def optional?
      not default_generator.equal?(NO_DEFAULT_GENERATOR)
    end

    # @deprecated Use a combination of the other instance methods instead
    def determine_from!(attr_hash, value_class)
      raw_value = attr_hash.fetch(name) do
        if default_generator.equal?(NO_DEFAULT_GENERATOR)
          raise MissingAttributes, "Attribute `#{value_class}\##{name}` has no value"
        else
          default_generator.call
        end
      end

      coerced_value = coerce(raw_value, value_class)
      if validate?(coerced_value)
        [name, coerced_value]
      else
        raise InvalidValue, "Attribute `#{value_class}\##{name}` is invalid: #{coerced_value.inspect}"
      end
    end

    def coerce(attr_value, value_class)
      return attr_value unless coercer # coercion not enabled

      if coercer.equal?(true)
        value_class.public_send(coercion_method, attr_value)
      else
        coercer.call(attr_value)
      end
    end

    def validate?(value)
      validator === value
    end

    def coercion_method
      "coerce_#{name}"
    end
  end
end
