module ValueSemantics
  class ArrayCoercer
    attr_reader :element_coercer

    def initialize(element_coercer = nil)
      @element_coercer = element_coercer
      freeze
    end

    def call(obj)
      if obj.respond_to?(:to_a)
        array = obj.to_a
        if element_coercer
          array.map { |element| element_coercer.call(element) }
        else
          array
        end
      else
        obj
      end
    end
  end
end
