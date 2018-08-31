require "spec_helper"

RSpec.describe ValueSemantics do
  context 'basic usage' do
    class Dog
      include ValueSemantics.for_attributes {
        name
        trained?
      }
    end

    it "has a keyword constructor and attr readers" do
      dog = Dog.new(name: 'Fido', trained?: true)

      expect(dog).to have_attributes(
        name: 'Fido',
        trained?: true,
      )
    end

    it "does not mutate constructor params" do
      params = { name: 'Fido', trained?: true }
      expect { Dog.new(params) }.not_to change { params }
    end

    it "does not define attr writers" do
      dog = Dog.new(name: 'Fido', trained?: true)

      expect{ dog.name = 'Goofy' }.to raise_error(NoMethodError, /name=/)
      expect{ dog.trained = false }.to raise_error(NoMethodError, /trained=/)
    end

    it "can not be constructed with attributes missing" do
      expect {
        dog = Dog.new(name: 'Fido')
      }.to raise_error(ArgumentError, /trained/)
    end

    it "can not be constructed with undefined attributes" do
      expect {
        Dog.new(name: 'Fido', trained?: true, meow: 'cattt', moo: 'cowww')
      }.to raise_error(ArgumentError, "Unrecognised attributes: :meow, :moo")
    end

    it "can do non-destructive updates" do
      sally = Dog.new(name: 'Sally', trained?: false)
      bob = sally.with(name: 'Bob')

      expect(bob).to have_attributes(name: 'Bob', trained?: false)
    end

    it "can be converted to a hash of attributes" do
      dog = Dog.new(name: 'Fido', trained?: false)

      expect(dog.to_h).to eq({ name: 'Fido', trained?: false })
    end

    it "has a human-friendly #inspect string" do
      dog = Dog.new(name: 'Fido', trained?: true)
      expect(dog.inspect).to eq('#<Dog name="Fido" trained?=true>')
    end

    it "has a human-friendly module name" do
      mod = Dog.ancestors[1]
      expect(mod.inspect).to include("ValueSemantics_Generated")
    end
  end

  context 'default values' do
    class Cat
      include ValueSemantics.for_attributes {
        name default: 'Kitty'
      }
    end

    it "uses the default if no value is given" do
      expect(Cat.new.name).to eq('Kitty')
    end

    it "allows the default to be overriden" do
      expect(Cat.new(name: 'Tomcat').name).to eq('Tomcat')
    end

    it "does not override nil" do
      expect(Cat.new(name: nil).name).to be_nil
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
      expect{ Birb.new(wings: 'smooth feet') }.to raise_error(ArgumentError, /wings/)
    end
  end

  context 'coercion' do
    class Person
      include ValueSemantics.for_attributes {
        likes Array do |value|
          coerce_likes(value)
        end
      }

      private

      def coerce_likes(likes)
        if likes.is_a?(String)
          likes.split(',').map(&:strip)
        else
          likes
        end
      end
    end

    it "calls the coercion block before validation" do
      sally = Person.new(likes: 'pie, cake, icecream')
      expect(sally.likes).to eq(['pie', 'cake', 'icecream'])

      bob = Person.new(likes: ['a', 'b', 'c'])
      expect(bob.likes).to eq(['a', 'b', 'c'])
    end

    it "still validates the coerced value" do
      expect { Person.new(likes: {}) }.to raise_error(ArgumentError, /likes/)
    end
  end

  context "equality" do
    class DogChild < Dog
    end

    let(:dog1) { Dog.new(name: 'Fido', trained?: true) }
    let(:dog2) { Dog.new(name: 'Fido', trained?: true) }
    let(:different) { Dog.new(name: 'Brutus', trained?: false) }
    let(:child) { DogChild.new(name: 'Fido', trained?: true) }

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

  context 'complicated usage' do
    class RocketSurgery
      include ValueSemantics.for_attributes {
        bang! maybe(Integer)
        qmark? default: 222
        bool boolean
        moo anything, default: {}
        woof either(String, Integer)
        widgets String, default: [4,5,6] { |value| coerce_widgets(value) }
      }

      def coerce_widgets(widgets)
        case widgets
        when Array then widgets.join('|')
        else widgets
        end
      end
    end

    it 'works' do
      rs = RocketSurgery.new(
        bang!: nil,
        bool: true,
        woof: 55,
      )

      expect(rs).to have_attributes(
        bang!: nil,
        qmark?: 222,
        bool: true,
        widgets: '4|5|6',
        moo: {},
        woof: 55,
      )
    end
  end

  describe ValueSemantics::Boolean do
    it 'matches true and false' do
      is_expected.to be === true
      is_expected.to be === false
    end

    it 'does not match nil or other values' do
      is_expected.not_to be === nil
      is_expected.not_to be === 5
    end
  end

  describe ValueSemantics::Maybe do
    subject { described_class.new(Integer) }

    it 'matches nil or the subvalidator' do
      is_expected.to be === nil
      is_expected.to be === 5
    end

    it 'does not match other values' do
      is_expected.not_to be === 'hello'
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
  end

  it "has a version number" do
    expect(ValueSemantics::VERSION).not_to be nil
  end
end

