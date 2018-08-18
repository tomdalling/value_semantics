require "spec_helper"

RSpec.describe ValueType do
  context 'basic usage' do
    class Dog < ValueType
      def_attr :name
      def_attr :trained?
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

    it "defines #==, #eql?, and #hash" do
      dog1 = Dog.new(name: 'Fido', trained?: true)
      dog2 = Dog.new(name: 'Fido', trained?: true)

      expect(dog1 == dog2).to be(true)
      expect(dog1.eql?(dog2)).to be(true)
      expect(dog1.hash).to eq(dog2.hash)

      diff_dog = dog1.with(name: 'Scruffy')

      expect(dog1 == diff_dog).to be(false)
      expect(dog1.eql?(diff_dog)).to be(false)
      expect(dog1.hash).not_to eq(diff_dog.hash)

      hash_key_test = { dog1 => 'woof' }.merge(dog2 => 'bark')
      expect(hash_key_test).to eq({ dog1 => 'bark' })
    end

    it "has a human-friendly #inspect string" do
      dog = Dog.new(name: 'Fido', trained?: true)
      expect(dog.inspect).to eq('#<Dog name="Fido" trained?=true>')
    end
  end

  context 'default values' do
    class Cat < ValueType
      def_attr :name, default: 'Kitty'
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

    class Birb < ValueType
      def_attr :wings, WingValidator
    end

    it "accepts values that pass the validator" do
      expect{ Birb.new(wings: 'feathery flappers') }.not_to raise_error
    end

    it "rejects values that fail the validator" do
      expect{ Birb.new(wings: 'smooth feet') }.to raise_error(ArgumentError, /wings/)
    end
  end

  context 'coercion' do
    class Person < ValueType
      def_attr :likes, Array do |likes|
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

  context 'complicated usage' do
    class RocketSurgery < ValueType
      def_attr :bang!, default: 111
      def_attr :qmark?, default: 222
      def_attr :widgets, String, default: [4,5,6] do |widgets|
        case widgets
        when Array then widgets.join('|')
        else widgets
        end
      end
    end

    it 'works' do
      expect(RocketSurgery.new).to have_attributes(
        bang!: 111,
        qmark?: 222,
        widgets: '4|5|6',
      )
    end
  end

  it "has a version number" do
    expect(ValueType::VERSION).not_to be nil
  end
end

