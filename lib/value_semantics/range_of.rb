module ValueSemantics
  class RangeOf
    attr_reader :subvalidator

    def initialize(subvalidator)
      @subvalidator = subvalidator
    end

    def ===(obj)
      return false unless Range === obj

      # begin or end can be nil, if the range is beginless or endless
      [obj.begin, obj.end].compact.all? do |element|
        subvalidator === element
      end
    end
  end
end
