require "spec_helper"

RSpec.describe ValueType do
  context 'basic usage' do
    class Dog < ValueType
      def_attributes do
        name
        trained?
      end
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

    it "disallows using def_attributes twice" do
      expect {
        class Dog
          def_attributes { whatever }
        end
      }.to raise_error(/already defined/)
    end
  end

  context 'default values' do
    class Cat < ValueType
      def_attributes do
        name default: 'Kitty'
      end
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
      def_attributes do
        wings WingValidator
      end
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
      def_attributes do
        likes Array do |likes|
          if likes.is_a?(String)
            likes.split(',').map(&:strip)
          else
            likes
          end
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

  context 'inheritance' do
    class Wolf < Dog
      def_attributes do
        teeth
      end
    end

    class EmptyWolf < Dog
    end

    it 'inherits attributes' do
      expect { EmptyWolf.new(name: 'Fido', trained?: false) }.not_to raise_error
      expect { Wolf.new(teeth: 1, name: 'Fido', trained?: false) }.not_to raise_error
    end
  end

  context 'complicated usage' do
    class RocketSurgery < ValueType
      def_attributes do
        bang! default: 111
        qmark? default: 222
        widgets String, default: [4,5,6] do |widgets|
          case widgets
          when Array then widgets.join('|')
          else widgets
          end
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

