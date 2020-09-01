require 'benchmark/ips'
require 'value_semantics'

module StringCoercer
  def self.call(obj)
    if obj.is_a?(Symbol)
      obj.to_s
    else
      obj
    end
  end
end

class VSPerson
  include ValueSemantics.for_attributes {
    name String, coerce: StringCoercer
    age Integer, default: nil
    born_at default_generator: Time.method(:now)
    a4 default: nil
  }
end


class ManualPerson
  attr_reader :name, :age

  def initialize(name:, age: nil, born_at: nil, a4: nil)
    @name =
      if name.is_a?(Symbol)
        name.to_s
      elsif name.is_a?(String)
        name
      else
        raise ArgumentError
      end

    @age =
      if age.is_a?(Integer)
        age
      else
        raise ArgumentError
      end

    @born_at = born_at || Time.now
    @a4 = a4
  end
end

Benchmark.ips do |x|
  x.report("VS") do |times|
    i = 0
    while i < times
      VSPerson.new(name: 'Jim', age: 5)
      i += 1
    end
  end

  x.report("Manual") do |times|
    i = 0
    while i < times
      ManualPerson.new(name: 'Jim', age: 5)
      i += 1
    end
  end

  x.compare!
end
