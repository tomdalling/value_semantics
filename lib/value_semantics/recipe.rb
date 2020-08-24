module ValueSemantics
  #
  # Contains all the configuration necessary to bake a ValueSemantics module
  #
  # @see ValueSemantics.bake_module
  # @see ClassMethods#value_semantics
  # @see DSL.run
  #
  class Recipe
    attr_reader :attributes

    def initialize(attributes:)
      @attributes = attributes
      freeze
    end
  end
end
