%w(
  anything
  array_coercer
  array_of
  attribute
  bool
  class_methods
  dsl
  either
  hash_of
  instance_methods
  recipe
  struct
  value_object_coercer
  version
).each do |filename|
  require_relative "value_semantics/#{filename}"
end

module ValueSemantics
  class Error < StandardError; end
  class UnrecognizedAttributes < Error; end
  class NoDefaultValue < Error; end
  class MissingAttributes < Error; end
  class InvalidValue < ArgumentError; end

  # @deprecated Use {Attribute::NOT_SPECIFIED} instead
  NOT_SPECIFIED = Attribute::NOT_SPECIFIED

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
  # Makes the +.value_semantics+ convenience method available to all classes
  #
  # +.value_semantics+ is a shortcut for {.for_attributes}. Instead of:
  #
  #     class Person
  #       include ValueSemantics.for_attributes {
  #         name String
  #       }
  #     end
  #
  # You can just write:
  #
  #     class Person
  #       value_semantics do
  #         name String
  #       end
  #     end
  #
  # Alternatively, you can +require 'value_semantics/monkey_patched'+, which
  # will call this method automatically.
  #
  def self.monkey_patch!
    Class.class_eval do
      # @!visibility private
      def value_semantics(&block)
        include ValueSemantics.for_attributes(&block)
      end
      private :value_semantics
    end
  end
end
