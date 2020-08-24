module ValueSemantics
  #
  # Represents a single attribute of a value class
  #
  class Attribute
    NOT_SPECIFIED = Object.new.freeze
    NO_DEFAULT_GENERATOR = lambda do
      raise NoDefaultValue, "Attribute does not have a default value"
    end

    attr_reader :name, :validator, :coercer, :default_generator

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
      freeze
    end

    def self.define(
      name,
      validator=Anything,
      default: NOT_SPECIFIED,
      default_generator: nil,
      coerce: nil
    )
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

    def determine_from(attr_hash, klass)
      raw_value = attr_hash.fetch(name) do
        if default_generator.equal?(NO_DEFAULT_GENERATOR)
          return [nil, MissingAttributes.new("Attribute `#{klass}\##{name}` has no value")]
        else
          default_generator.call
        end
      end

      coerced_value = coerce(raw_value, klass)

      if validate?(coerced_value)
        [coerced_value, nil]
      else
        [nil, InvalidValue.new("Attribute `#{klass}\##{name}` is invalid: #{coerced_value.inspect}")]
      end
    end

    # @deprecated Use {#determine_from} instead
    def determine_from!(attr_hash, klass)
      value, error = determine_from(attr_hash, klass)
      if error
        raise error
      else
        [name, value]
      end
    end

    def coerce(attr_value, klass)
      return attr_value unless coercer # coercion not enabled

      if coercer.equal?(true)
        klass.public_send(coercion_method, attr_value)
      else
        coercer.call(attr_value)
      end
    end

    def validate?(value)
      validator === value
    end

    def instance_variable
      '@' + name.to_s.chomp('!').chomp('?')
    end

    def coercion_method
      "coerce_#{name}"
    end
  end
end
