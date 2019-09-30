module ValueSemantics
  class Error < StandardError; end
  class UnrecognizedAttributes < Error; end
  class NoDefaultValue < Error; end
  class MissingAttributes < Error; end

  NOT_SPECIFIED = Object.new.freeze

  #
  # Creates a module via the DSL
  #
  # @yield The block containing the DSL
  # @return [Module]
  #
  # @see DSL
  # @see InstanceMethods
  #
  def self.for_attributes(&block)
    recipe = DSL.run(&block)
    bake_module(recipe)
  end

  #
  # Creates a module from a {Recipe}
  #
  # @param recipe [Recipe]
  # @return [Module]
  #
  def self.bake_module(recipe)
    Module.new do
      const_set(:VALUE_SEMANTICS_RECIPE__, recipe)
      include(InstanceMethods)

      # define the attr readers
      recipe.attributes.each do |attr|
        module_eval("def #{attr.name}; #{attr.instance_variable}; end")
      end

      def self.included(base)
        base.const_set(:ValueSemantics_Attributes, self)
        base.extend(ClassMethods)
      end
    end
  end

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
      self::VALUE_SEMANTICS_RECIPE__
    end
  end

  #
  # All the instance methods available on ValueSemantics objects
  #
  module InstanceMethods
    #
    # Creates a value object based on a Hash of attributes
    #
    # @param given_attrs [Hash] a hash of attributes, with symbols for keys
    # @raise [UnrecognizedAttributes] if given_attrs contains keys that are not attributes
    # @raise [MissingAttributes] if given_attrs is missing any attributes that do not have defaults
    # @raise [ArgumentError] if any attribute values do no pass their validators
    #
    def initialize(given_attrs = {})
      remaining_attrs = given_attrs.dup

      self.class.value_semantics.attributes.each do |attr|
        key, value = attr.determine_from!(remaining_attrs, self.class)
        instance_variable_set(attr.instance_variable, value)
        remaining_attrs.delete(key)
      end

      unless remaining_attrs.empty?
        unrecognised = remaining_attrs.keys.map(&:inspect).join(', ')
        raise UnrecognizedAttributes, "Unrecognized attributes: #{unrecognised}"
      end
    end

    #
    # Creates a copy of this object, with the given attributes changed (non-destructive update)
    #
    # @param new_attrs [Hash] the attributes to change
    # @return A new object, with the attribute changes applied
    #
    def with(new_attrs)
      self.class.new(to_h.merge(new_attrs))
    end

    #
    # @return [Hash] all of the attributes
    #
    def to_h
      self.class.value_semantics.attributes
        .map { |attr| [attr.name, public_send(attr.name)] }
        .to_h
    end

    #
    # Loose equality
    #
    # @return [Boolean] whether all attributes are equal, and the object
    #                   classes are ancestors of eachother in any way
    #
    def ==(other)
      (other.is_a?(self.class) || is_a?(other.class)) && other.to_h.eql?(to_h)
    end

    #
    # Strict equality
    #
    # @return [Boolean] whether all attribuets are equal, and both objects
    #                   has the exact same class
    #
    def eql?(other)
      other.class.equal?(self.class) && other.to_h.eql?(to_h)
    end

    #
    # Unique-ish integer, based on attributes and class of the object
    #
    def hash
      to_h.hash ^ self.class.hash
    end

    def inspect
      attrs = to_h
        .map { |key, value| "#{key}=#{value.inspect}" }
        .join(" ")

      "#<#{self.class} #{attrs}>"
    end

    def pretty_print(pp)
      pp.object_group(self) do
        to_h.each do |attr, value|
          pp.breakable
          pp.text("#{attr}=")
          pp.pp(value)
        end
      end
    end
  end

  #
  # Represents a single attribute of a value class
  #
  class Attribute
    NO_DEFAULT_GENERATOR = lambda do
      raise NoDefaultValue, "Attribute does not have a default value"
    end

    attr_reader :name, :validator, :coercer, :default_generator

    def initialize(name:,
                   default_generator: NO_DEFAULT_GENERATOR,
                   validator: Anything,
                   coercer: nil)
      @name = name.to_sym
      @default_generator = default_generator
      @validator = validator
      @coercer = coercer
      freeze
    end

    def self.define(name,
                    validator=Anything,
                    default: NOT_SPECIFIED,
                    default_generator: nil,
                    coerce: nil)
      generator = begin
        if default_generator && !default.equal?(NOT_SPECIFIED)
          raise ArgumentError, "Attribute '#{name}' can not have both a :default and a :default_generator"
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

    def determine_from!(attr_hash, klass)
      raw_value = attr_hash.fetch(name) do
        if default_generator.equal?(NO_DEFAULT_GENERATOR)
          raise MissingAttributes, "Value missing for attribute '#{name}'"
        else
          default_generator.call
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

  #
  # Contains all the configuration necessary to bake a ValueSemantics module
  #
  # @see ValueSemantics.bake_module
  #
  class Recipe
    attr_reader :attributes

    def initialize(attributes:)
      @attributes = attributes
      freeze
    end
  end

  #
  # Builds a {Recipe} via DSL methods
  #
  # DSL blocks are <code>instance_eval</code>d against an object of this class.
  #
  # @see Recipe
  # @see ValueSemantics.for_attributes
  #
  class DSL
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

    def def_attr(*args)
      __attributes << Attribute.define(*args)
    end

    def method_missing(name, *args)
      if respond_to_missing?(name)
        def_attr(name, *args)
      else
        super
      end
    end

    def respond_to_missing?(method_name, _include_private=nil)
      first_letter = method_name.to_s.each_char.first
      first_letter.eql?(first_letter.downcase)
    end
  end

  #
  # Validator that only matches `true` and `false`
  #
  module Bool
    # @return [Boolean]
    def self.===(value)
      true.equal?(value) || false.equal?(value)
    end
  end

  #
  # Validator that matches any and all values
  #
  module Anything
    # @return [true]
    def self.===(_)
      true
    end
  end

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

  #
  # Validator that matches arrays if each element matches a given subvalidator
  #
  class ArrayOf
    attr_reader :element_validator

    def initialize(element_validator)
      @element_validator = element_validator
      freeze
    end

    # @return [Boolean]
    def ===(value)
      Array === value && value.all? { |element| element_validator === element }
    end
  end

  #
  # ValueSemantics equivalent of the Struct class from the Ruby standard
  # library
  #
  class Struct
    #
    # Creates a new Class with ValueSemantics mixed in
    #
    # @yield a block containing ValueSemantics DSL
    # @return [Class] the newly created class
    #
    def self.new(&block)
      klass = Class.new
      klass.include(ValueSemantics.for_attributes(&block))
      klass
    end
  end

end
