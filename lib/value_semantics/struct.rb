module ValueSemantics
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
