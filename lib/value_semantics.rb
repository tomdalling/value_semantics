module ValueSemantics
  def self.for_attributes(&block)
    attributes = DSL.run(&block)
    generate_module(attributes)
  end

  def self.generate_module(attributes)
    Module.new.tap do |m|
      # include all the instance methods
      m.include(Semantics)

      # define the attr readers
      attributes.each do |attr|
        m.module_eval("def #{attr.name}; #{attr.instance_variable}; end")
      end

      # define BaseClass.attributes class method
      m.const_set(:ATTRIBUTES__, attributes)
      m.define_singleton_method(:included) do |base|
        base.const_set(:ValueSemantics_Generated, m)
        class << base
          def attributes
            self::ATTRIBUTES__
          end
        end
      end
    end
  end

  module Semantics
    def initialize(given_attrs = {})
      remaining_attrs = given_attrs.dup

      self.class.attributes.each do |attr|
        key, value = attr.determine_from!(remaining_attrs, self.class)
        instance_variable_set(attr.instance_variable, value)
        remaining_attrs.delete(key)
      end

      unless remaining_attrs.empty?
        unrecognised = remaining_attrs.keys.map(&:inspect).join(', ')
        raise ArgumentError, "Unrecognised attributes: #{unrecognised}"
      end
    end

    def with(new_attrs)
      self.class.new(to_h.merge(new_attrs))
    end

    def to_h
      self.class.attributes
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
  end

  class Attribute
    attr_reader :name, :has_default, :default_value

    def initialize(name:, has_default:, default_value:, validator:)
      @name = name.to_sym
      @has_default = has_default
      @default_value = default_value
      @validator = validator
      freeze
    end

    def determine_from!(attr_hash, klass)
      raw_value = attr_hash.fetch(name) do
        if has_default
          default_value
        else
          raise ArgumentError, "Value missing for attribute '#{name}'"
        end
      end

      coerced_value = coerce(raw_value, klass)

      if validate?(coerced_value)
        [name, coerced_value]
      else
        raise ArgumentError, "Value for attribute '#{name}' is not valid: #{coerced_value.inspect}"
      end
    end

    def coerce(attr_value, klass)
      if klass.respond_to?(coercion_method)
        klass.public_send(coercion_method, attr_value)
      else
        attr_value
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

    def instance_variable
      '@' + name.to_s.chomp('!').chomp('?')
    end

    def coercion_method
      "coerce_#{name}"
    end
  end

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

    def boolean
      Boolean
    end

    def either(*subvalidators)
      Either.new(subvalidators)
    end

    def anything
      Anything
    end

    def array_of(element_validator)
      ArrayOf.new(element_validator)
    end

    def declare_attribute(attr_name, validator=Anything, default: NOT_SPECIFIED)

      __attributes << Attribute.new(
        name: attr_name,
        has_default: default != NOT_SPECIFIED,
        default_value: default,
        validator: validator,
      )
    end

    def method_missing(*args, &block)
      declare_attribute(*args, &block)
    end

    def respond_to_missing?(method_name, include_private = false)
      true
    end
  end

  module Boolean
    extend self

    def ===(value)
      true.eql?(value) || false.eql?(value)
    end
  end

  module Anything
    def self.===(value)
      true
    end
  end

  class Either
    attr_reader :subvalidators

    def initialize(subvalidators)
      @subvalidators = subvalidators
      freeze
    end

    def ===(value)
      subvalidators.any? { |sv| sv === value }
    end
  end

  class ArrayOf
    attr_reader :element_validator

    def initialize(element_validator)
      @element_validator = element_validator
      freeze
    end

    def ===(value)
      Array === value && value.all? { |element| element_validator === element }
    end
  end

end
