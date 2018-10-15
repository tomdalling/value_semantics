module ValueSemantics
  def self.for_attributes(&block)
    attributes = DSL.run(&block)
    generate_module(attributes.freeze)
  end

  def self.generate_module(attributes)
    Module.new do
      # include all the instance methods
      include(Semantics)

      # define the attr readers
      attributes.each do |attr|
        module_eval("def #{attr.name}; #{attr.instance_variable}; end")
      end

      # define BaseClass.attributes class method
      const_set(:ATTRIBUTES__, attributes)
      def self.included(base)
        base.const_set(:ValueSemantics_Generated, self)
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
      (other.is_a?(self.class) || is_a?(other.class)) && other.to_h.eql?(to_h)
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
    NOT_SPECIFIED = Object.new.freeze

    attr_reader :name, :validator, :coercer

    def initialize(name:, default_value:, validator:, coercer:)
      @name = name.to_sym
      @default_value = default_value
      @validator = validator
      @coercer = coercer
      freeze
    end

    def determine_from!(attr_hash, klass)
      raw_value = attr_hash.fetch(name) do
        if default_specified?
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
      case coercer
      when false, nil then attr_value # no coercion
      when true then klass.public_send(coercion_method, attr_value)
      else coercer.call(attr_value)
      end
    end

    def default_specified?
      @default_value != NOT_SPECIFIED
    end

    def default_value
      if default_specified?
        @default_value
      else
        fail "Attribute does not have a default value"
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

  class DSL
    def self.run(&block)
      dsl = new
      dsl.instance_eval(&block)
      dsl.__attributes
    end

    attr_reader :__attributes

    def initialize
      @__attributes = []
    end

    def Boolean
      Boolean
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

    def def_attr(attr_name, validator=Anything, default: Attribute::NOT_SPECIFIED, coerce: false)
      __attributes << Attribute.new(
        name: attr_name,
        validator: validator,
        default_value: default,
        coercer: coerce
      )
    end

    def method_missing(name, *args)
      if respond_to_missing?(name)
        def_attr(name, *args)
      else
        super
      end
    end

    def respond_to_missing?(method_name, _include_private=nil)
      first_letter = method_name[0]
      first_letter.eql?(first_letter.downcase)
    end
  end

  module Boolean
    extend self

    def ===(value)
      true.equal?(value) || false.equal?(value)
    end
  end

  module Anything
    def self.===(_)
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
