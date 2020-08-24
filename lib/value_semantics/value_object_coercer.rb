module ValueSemantics
  #
  # A coercer for converting hashes into instances of value classes
  #
  # The coercer will coerce hash-like values into an instance of the value
  # class, using the hash for attribute values. It will return non-hash-like
  # values unchanged. It will also return hash-like values unchanged if they do
  # not contain all required attributes of the value class.
  #
  class ValueObjectCoercer
    attr_reader :value_class

    def initialize(value_class)
      @value_class = value_class
    end

    def call(obj)
      attrs = coerce_to_attr_hash(obj)
      if attrs
        value_class.new(attrs)
      else
        obj
      end
    end

    private
      NOT_FOUND = Object.new.freeze

      def coerce_to_attr_hash(obj)
        return nil unless obj.respond_to?(:to_h)
        obj_hash = obj.to_h

        {}.tap do |attrs|
          value_class.value_semantics.attributes.each do |attr_def|
            name = attr_def.name
            value = obj_hash.fetch(name) do
              obj_hash.fetch(name.to_s, NOT_FOUND)
            end
            attrs[name] = value unless value.equal?(NOT_FOUND)
          end
        end
      end
  end
end
