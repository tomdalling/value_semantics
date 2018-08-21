class ValueType
  @attributes = [].freeze

  def self.def_attributes(&block)
    fail "Attributes already defined for #{self}" if @attributes

    dsl = DSL.new
    dsl.instance_exec(&block)
    @attributes = (dsl.__attributes + superclass.attributes).freeze

    @attributes.each do |attr|
      class_eval <<~END_ATTR_READER
        def #{attr.name}
          #{attr.instance_variable}
        end
      END_ATTR_READER
    end
  end

  def self.attributes
    @attributes || superclass.attributes
  end

  def initialize(given_attrs = {})
    remaining_attrs = given_attrs.dup

    self.class.attributes.each do |attr|
      key, value = attr.determine_from!(remaining_attrs)
      instance_variable_set(attr.instance_variable, value)
      remaining_attrs.delete(key)
    end

    unless remaining_attrs.empty?
      extra_attrs = remaining_attrs.keys.map(&:inspect).join(', ')
      raise ArgumentError, "Unrecognised attributes: #{extra_attrs}"
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

  private

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
      value = begin
        if attr_hash.key?(name)
          coerce(attr_hash.fetch(name))
        elsif has_default
          coerce(default_value)
        else
          raise ArgumentError, "Value missing for attribute '#{name}'"
        end
      end

      unless validate?(value)
        raise ArgumentError, "Value for attribute '#{name}' is not valid: #{value.inspect}"
      end

      [name, value]
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

  NOT_SPECIFIED = Object.new

  class DSL
    attr_reader :__attributes

    def initialize
      @__attributes = []
    end

    def method_missing(attr_name, validator = AnythingValidator, default: NOT_SPECIFIED, &coercion_block)
      #TODO: check for duplicate attrs
      __attributes << Attribute.new(
        name: attr_name,
        has_default: default != NOT_SPECIFIED,
        default_value: default,
        validator: validator,
        coercer: coercion_block || IdentityCoercer,
      )
    end

    def respond_to_missing?(*)
      true
    end
  end
end
