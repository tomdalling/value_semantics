module ValueSemantics
  def self.for_attributes(&block)
    attributes = DSL.run(&block)

    Module.new.tap do |m|
      m.const_set(:ATTRIBUTES, attributes)
      m.include(ValueSemantics)
      attributes.each do |attr|
        m.module_eval("def #{attr.name}; #{attr.instance_variable}; end")
      end
    end
  end

  def initialize(given_attrs = {})
    remaining_attrs = given_attrs.dup

    attribute_definitions.each do |attr|
      key, value = attr.determine_from!(remaining_attrs)
      instance_variable_set(attr.instance_variable, value)
      remaining_attrs.delete(key)
    end

    unless remaining_attrs.empty?
      unrecognised = remaining_attrs.keys.map(&:inspect).join(', ')
      raise ArgumentError, "Unrecognised attributes: #{unrecognised}"
    end
  end

  def attribute_definitions
    self.class::ATTRIBUTES
  end

  def with(new_attrs)
    self.class.new(to_h.merge(new_attrs))
  end

  def to_h
    attribute_definitions
      .map { |attr| [attr.name, public_send(attr.name)] }
      .to_h
  end

  def ==(other)
    (other.is_a?(self.class) || is_a?(other.class)) && other.to_h == to_h
  end

  def eql?(other)
    other.class.equal?(self.class) && other.to_h.eql?(to_h)
  end

  def hash
    @__hash ||= (to_h.hash ^ self.class.hash)
  end

  def inspect
    attrs = to_h
      .map { |key, value| "#{key}=#{value.inspect}" }
      .join(" ")

    "#<#{self.class} #{attrs}>"
  end

  module AnythingValidator
    def self.===(value)
      true
    end
  end

  module IdentityCoercer
    def self.call(value)
      value
    end
  end
end

module ValueSemantics
  class Attribute
    attr_reader :name, :has_default, :default_value

    def initialize(name:, has_default:, default_value:, validator:, coercer:)
      @name = name.to_sym
      @has_default = has_default
      @default_value = default_value
      @validator = validator
      @coercer = coercer
      freeze
    end

    def determine_from!(attr_hash)
      raw_value = attr_hash.fetch(name) do
        if has_default
          default_value
        else
          raise ArgumentError, "Value missing for attribute '#{name}'"
        end
      end

      coerced_value = coerce(raw_value)

      if validate?(coerced_value)
        [name, coerced_value]
      else
        raise ArgumentError, "Value for attribute '#{name}' is not valid: #{coerced_value.inspect}"
      end
    end

    def default_value
      if has_default
        @default_value
      else
        fail "Attribute does not have a default value"
      end
    end

    def validate?(value)
      !!(@validator === value)
    end

    def coerce(value)
      @coercer.call(value)
    end

    def instance_variable
      '@' + name.to_s.chomp('!').chomp('?')
    end
  end
end

module ValueSemantics
  class DSL
    NOT_SPECIFIED = Object.new

    def self.run(&block)
      dsl = new
      dsl.instance_eval(&block)
      dsl.__attributes
    end

    attr_reader :__attributes

    def initialize
      @__attributes = []
    end

    def method_missing(attr_name, validator=AnythingValidator,
      default: NOT_SPECIFIED, &coercion_block)

      __attributes << Attribute.new(
        name: attr_name,
        has_default: default != NOT_SPECIFIED,
        default_value: default,
        validator: validator,
        coercer: coercion_block || IdentityCoercer,
      )
    end

    def respond_to_missing?(method_name, include_private = false)
      true
    end
  end
end
