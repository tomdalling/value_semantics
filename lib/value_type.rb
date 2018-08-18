class ValueType
  def self.def_attr(name, validator = AnythingValidator, default: NOT_SPECIFIED, &coercion_block)
    attr = Attribute.new(
      name: name,
      default: default,
      validator: validator,
      coercer: coercion_block || IdentityCoercer,
    )

    if attributes.map(&:name).include?(attr.name)
      fail "Attribute '#{name}' already defined"
    end

    attributes << attr

    class_eval <<~END_ATTR_READER
      def #{attr.name}
        #{attr.instance_variable}
      end
    END_ATTR_READER
  end

  def self.attributes
    @attributes ||= []
  end

  def initialize(given_attrs = {})
    remaining_attrs = given_attrs.dup

    self.class.attributes.each do |attr|
      key, value = attr.determine_from!(remaining_attrs)
      instance_variable_set(attr.instance_variable, value)
      remaining_attrs.delete(key)
    end

    unless remaining_attrs.empty?
      raise ArgumentError, "Unrecognised attributes: " + remaining_attrs.keys.map(&:inspect).join(', ')
    end
  end

  def with(new_attrs)
    self.class.new(to_h.merge(new_attrs))
  end

  def to_h
    self.class.attributes
      .map { |attr| [attr.name, send(attr.name)] }
      .to_h
  end

  def ==(other)
    (other.is_a?(self.class) || self.is_a?(other.class)) && other.to_h == self.to_h
  end

  def eql?(other)
    other.class == self.class && other.to_h == self.to_h
  end

  def hash
    @__hash ||= (to_h.hash ^ self.class.hash)
  end

  def inspect
    attrs = to_h
      .map { |key, value| "#{key}=#{value.inspect}" }
      .join(" ")

    "#<#{self.class.name} #{attrs}>"
  end

  private

  class Attribute
    attr_reader :name

    def initialize(name:, default:, validator:, coercer:)
      @name = name.to_sym
      @default = default
      @validator = validator
      @coercer = coercer
    end

    def determine_from!(attr_hash)
      value = begin
        if attr_hash.key?(name)
          coerce(attr_hash.fetch(name))
        elsif has_default?
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

    def has_default?
      @default != NOT_SPECIFIED
    end

    def default_value
      if has_default?
        @default
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
end
