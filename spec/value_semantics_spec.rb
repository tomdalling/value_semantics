require "spec_helper"
require "pp"

RSpec.describe ValueSemantics do
  let(:dog_class) do
    Class.new do
      include ValueSemantics.for_attributes {
        name
        trained?
      }
    end
  end

  def with_constant(const_name, const_value)
    Object.const_set(const_name, const_value)
    yield
  ensure
    Object.send(:remove_const, const_name)
  end

  context 'basic usage' do
    it "has a keyword constructor, attr readers, and ivars" do
      dog = dog_class.new(name: 'Fido', trained?: true)

      expect(dog).to have_attributes(
        name: 'Fido',
        trained?: true,
      )

      expect(dog.instance_variable_get(:@name)).to eq('Fido')
      expect(dog.instance_variable_get(:@trained)).to eq(true)
    end

    it "does not mutate constructor params" do
      params = { name: 'Fido', trained?: true }
      expect { dog_class.new(params) }.not_to change { params }
    end

    it "does not define attr writers" do
      dog = dog_class.new(name: 'Fido', trained?: true)

      expect{ dog.name = 'Goofy' }.to raise_error(NoMethodError, /name=/)
      expect{ dog.trained = false }.to raise_error(NoMethodError, /trained=/)
    end

    it "can not be constructed with attributes missing" do
      expect {
        dog = dog_class.new(name: 'Fido')
      }.to raise_error(ValueSemantics::MissingAttributes, "Value missing for attribute 'trained?'")
    end

    it "can not be constructed with undefined attributes" do
      expect {
        dog_class.new(name: 'Fido', trained?: true, meow: 'cattt', moo: 'cowww')
      }.to raise_error(ValueSemantics::UnrecognizedAttributes, "Unrecognized attributes: :meow, :moo")
    end

    it "can do non-destructive updates" do
      sally = dog_class.new(name: 'Sally', trained?: false)
      bob = sally.with(name: 'Bob')

      expect(bob).to have_attributes(name: 'Bob', trained?: false)
    end

    it "can be converted to a hash of attributes" do
      dog = dog_class.new(name: 'Fido', trained?: false)

      expect(dog.to_h).to eq({ name: 'Fido', trained?: false })
    end

    it "has a human-friendly #inspect string" do
      with_constant(:Doggums, dog_class) do
        dog = Doggums.new(name: 'Fido', trained?: true)
        expect(dog.inspect).to eq('#<Doggums name="Fido" trained?=true>')
      end
    end

    it "has nice pp output" do
      output = StringIO.new

      with_constant(:Doggums, dog_class) do
        dog = Doggums.new(name: "Fido", trained?: true)
        PP.pp(dog, output, 3)
      end

      expect(output.string).to eq(<<~END_PP)
        #<Doggums
         name="Fido"
         trained?=true>
      END_PP
    end

    it "has a human-friendly module name" do
      with_constant(:Doggums, dog_class) do
        mod = Doggums.ancestors[1]
        expect(mod.name).to eq("Doggums::ValueSemantics_Attributes")
      end
    end

    it "has a frozen recipe" do
      vs = dog_class.value_semantics
      expect(vs).to be_a(ValueSemantics::Recipe)
      expect(vs).to be_frozen
      expect(vs.attributes).to be_frozen
      expect(vs.attributes.first).to be_frozen
    end
  end

  context 'default values' do
    let(:cat) do
      Class.new do
        include ValueSemantics.for_attributes {
          name default: 'Kitty'
          scratch_proc default: ->{ "scratch" }
          born_at default_generator: ->{ Time.now }
        }
      end
    end

    it "uses the default if no value is given" do
      expect(cat.new.name).to eq('Kitty')
    end

    it "allows the default to be overriden" do
      expect(cat.new(name: 'Tomcat').name).to eq('Tomcat')
    end

    it "does not override nil" do
      expect(cat.new(name: nil).name).to be_nil
    end

    it "allows procs as default values" do
      expect(cat.new.scratch_proc.call).to eq("scratch")
    end

    it "can generate defaults with a proc" do
      expect(cat.new.born_at).to be_a(Time)
    end

    it "does not allow both `default:` and `default_generator:` options" do
      expect do
        ValueSemantics.for_attributes {
          both default: 5, default_generator: ->{ rand }
        }
      end.to raise_error(ArgumentError, "Attribute 'both' can not have both a :default and a :default_generator")
    end
  end

  context 'validation' do
    module WingValidator
      def self.===(value)
        /feathery/.match(value)
      end
    end

    class Birb
      include ValueSemantics.for_attributes {
        wings WingValidator
      }
    end

    it "accepts values that pass the validator" do
      expect{ Birb.new(wings: 'feathery flappers') }.not_to raise_error
    end

    it "rejects values that fail the validator" do
      expect{ Birb.new(wings: 'smooth feet') }.to raise_error(ArgumentError,
        "Value for attribute 'wings' is not valid: \"smooth feet\"")
    end
  end

  context 'coercion' do
    module Callable
      def self.call(x)
        "callable: #{x}"
      end
    end

    class CoercionTest
      include ValueSemantics.for_attributes {
        no_coercion String, default: ""
        with_true String, coerce: true, default: ""
        with_callable String, coerce: Callable, default: ""
        double_it String, coerce: ->(x) { x * 2 }, default: "42"
      }

      private

      def self.coerce_with_true(value)
        "class_method: #{value}"
      end

      def self.coerce_no_coercion(value)
        fail "Should never get here"
      end
    end

    it "does not call coercion methods by default" do
      subject = CoercionTest.new(no_coercion: 'dinklage')
      expect(subject.no_coercion).to eq('dinklage')
    end

    it "calls a class method when coerce: true" do
      subject = CoercionTest.new(with_true: 'peter')
      expect(subject.with_true).to eq('class_method: peter')
    end

    it "calls obj.call when coerce: obj" do
      subject = CoercionTest.new(with_callable: 'daenerys')
      expect(subject.with_callable).to eq('callable: daenerys')
    end

    it "coerces default values" do
      subject = CoercionTest.new
      expect(subject.double_it).to eq('4242')
    end

    it "performs coercion before validation" do
      expect {
        CoercionTest.new(double_it: 6)
      }.to raise_error(ArgumentError, "Value for attribute 'double_it' is not valid: 12")
    end
  end

  context "equality" do
    let(:puppy_class) { Class.new(dog_class) }

    let(:dog1) { dog_class.new(name: 'Fido', trained?: true) }
    let(:dog2) { dog_class.new(name: 'Fido', trained?: true) }
    let(:different) { dog_class.new(name: 'Brutus', trained?: false) }
    let(:child) { puppy_class.new(name: 'Fido', trained?: true) }

    it "defines loose equality between subclasses with #===" do
      expect(dog1).to eq(dog2)
      expect(dog1).not_to eq(different)
      expect(dog1).not_to eq("hello")

      expect(dog1).to eq(child)
      expect(child).to eq(dog1)
    end

    it "defines strict equality with #eql?" do
      expect(dog1.eql?(dog2)).to be(true)
      expect(dog1.eql?(different)).to be(false)

      expect(dog1.eql?(child)).to be(false)
      expect(child.eql?(dog1)).to be(false)
    end

    it "allows objects to be used as keys in Hash objects" do
      expect(dog1.hash).to eq(dog2.hash)
      expect(dog1.hash).not_to eq(different.hash)

      hash_key_test = { dog1 => 'woof', different => 'diff' }.merge(dog2 => 'bark')
      expect(hash_key_test).to eq({ dog1 => 'bark', different => 'diff' })
    end

    it "hashes differently depending on class" do
      expect(dog1.hash).not_to eq(child.hash)
    end
  end

  context 'complicated DSL usage' do
    let(:rocket_surgery_class) do
      Class.new do
        include ValueSemantics.for_attributes {
          qmark? default: 222
          bool Bool()
          moo Anything(), default: {}
          woof! Either(String, Integer)
          widgets String, default: [4,5,6], coerce: true
          def_attr 'array_test', ArrayOf(Integer)
        }

        def self.coerce_widgets(widgets)
          case widgets
          when Array then widgets.join('|')
          else widgets
          end
        end
      end
    end

    it 'works' do
      rs = rocket_surgery_class.new(
        bool: true,
        woof!: 55,
        array_test: [1,2,3],
      )

      expect(rs).to have_attributes(
        qmark?: 222,
        bool: true,
        widgets: '4|5|6',
        moo: {},
        woof!: 55,
        array_test: [1,2,3],
      )
    end
  end

  describe ValueSemantics::Bool do
    it 'matches true and false' do
      is_expected.to be === true
      is_expected.to be === false
    end

    it 'does not match nil or other values' do
      is_expected.not_to be === nil
      is_expected.not_to be === 5
    end
  end

  describe ValueSemantics::Either do
    subject { described_class.new([Integer, String]) }

    it 'matches any of the subvalidators' do
      is_expected.to be === 5
      is_expected.to be === 'hello'
    end

    it 'does not match anything else' do
      is_expected.not_to be === nil
      is_expected.not_to be === [1,2,3]
    end

    it 'is frozen' do
      is_expected.to be_frozen
    end
  end

  describe ValueSemantics::ArrayOf do
    subject { described_class.new(Integer) }

    it 'uses the subvalidator for each element in the array' do
      is_expected.to be === [1,2,3]
      is_expected.to be === []
    end

    it 'does not match anything else' do
      is_expected.not_to be === nil
      is_expected.not_to be === 'hello'
      is_expected.not_to be === %i(1 2 3)
      is_expected.not_to be === Set.new([1, 2, 3])
    end

    it 'is frozen' do
      is_expected.to be_frozen
    end
  end

  describe ValueSemantics::DSL do
    subject { described_class.new }

    it 'turns method calls into attributes' do
      subject.fOO(Integer, default: 3, coerce: 'hi')

      expect(subject.attributes.first).to have_attributes(
        name: :fOO,
        validator: Integer,
        coercer: 'hi',
      )
      expect(subject.attributes.first.default_generator.call).to eq(3)
    end

    it 'does not interfere with existing methods' do
      expect(subject.respond_to?(:Float, true)).to be(true)
      expect(subject.respond_to?(:Float)).to be(false)
    end

    it 'disallows methods that begin with capitals' do
      expect { subject.Hello }.to raise_error(NoMethodError)
      expect(subject.respond_to?(:Wigwam)).to be(false)
      expect(subject.respond_to?(:Wigwam, true)).to be(false)
    end
  end

  describe ValueSemantics::Attribute do
    subject { described_class.new(name: :whatever) }

    it 'raises if attempting to use missing default attribute' do
      expect { subject.default_generator.call }.to raise_error(
        "Attribute does not have a default value"
      )
    end

    it 'has default attributes' do
      is_expected.to have_attributes(
        name: :whatever,
        validator: be(ValueSemantics::Anything),
        coercer: nil,
        default_generator: be(ValueSemantics::Attribute::NO_DEFAULT_GENERATOR),
      )
    end
  end

  describe ValueSemantics::Struct do
    subject do
      described_class.new do
        attr1 Array, default: [4,5,6]
        attr2
      end
    end

    it "returns a value class, like Struct.new does" do
      expect(subject).to be_a(Class)
      expect(subject).not_to be(Class)
      expect(subject.value_semantics).to be_a(ValueSemantics::Recipe)
      expect(subject.value_semantics.attributes.count).to eq(2)
    end

    it "makes instances that work like normal ValueSemantics objects" do
      instance = subject.new(attr2: 2)
      expect(instance.attr1).to eq([4,5,6])
      expect(instance.attr2).to eq(2)
    end
  end

  it "has a version number" do
    expect(ValueSemantics::VERSION).not_to be nil
  end
end

