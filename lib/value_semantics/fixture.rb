begin
  require 'test_bench/fixture'
rescue LoadError
  raise "ValueSemantics::Fixture requires the `test_bench-fixture` gem"
end

require 'value_semantics'

class ValueSemantics::Fixture
  include TestBench::Fixture

  def initialize(value_class:, valid_attrs: {})
    @value_class, @valid_attrs = value_class, valid_attrs
  end

  def assert_attrs(*attrs_list)
    each_attr(attrs_list) do |attr|
      test do
        detail_attr '.new', 'should accept', attr
        refute_raises ValueSemantics::InvalidValue do
          @value_class.new(@valid_attrs.merge(attr))
        end
      end

      test do
        detail_attr '#with', 'should accept', attr
        refute_raises ValueSemantics::InvalidValue do
          @value_class.new(@valid_attrs).with(attr)
        end
      end
    end
  end

  def refute_attrs(*attrs_list)
    each_attr(attrs_list) do |attr|
      test do
        detail_attr '.new', 'should REJECT', attr
        assert_raises ValueSemantics::InvalidValue do
          @value_class.new(@valid_attrs.merge(attr))
        end
      end

      test do
        detail_attr '#with', 'should REJECT', attr
        assert_raises ValueSemantics::InvalidValue do
          @value_class.new(@valid_attrs).with(attr)
        end
      end
    end
  end

  private

    def detail_attr(method_name, expectation, attr)
      raise ArgumentError unless attr.size == 1
      detail "#{@value_class}#{method_name} #{expectation}: #{attr.inspect}"
    end

    def each_attr(attrs_list)
      attrs_list.each do |attrs|
        attrs.each do |name, value|
          yield({ name => value })
        end
      end
    end
end
