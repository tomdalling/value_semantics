RSpec.describe ValueSemantics::DSL do
  subject { described_class.new }

  it 'turns method calls into attributes' do
    subject.fOO(Integer, default: 3, coerce: 'hi')

    expect(subject.__attributes.first).to have_attributes(
      name: :fOO,
      validator: Integer,
      coercer: 'hi',
    )
    expect(subject.__attributes.first.default_generator.call).to eq(3)
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

  it 'has a built-in Either matcher' do
    validator = subject.Either(String, Integer)
    expect(validator).to be === 5
  end

  it 'has a built-in Anything matcher' do
    validator = subject.Anything
    expect(validator).to be === RSpec
  end

  it 'has a built-in Bool matcher' do
    validator = subject.Bool
    expect(validator).to be === false
  end

  it 'has a built-in ArrayOf matcher' do
    validator = subject.ArrayOf(String)
    expect(validator).to be === %w(1 2 3)
  end

  it 'has a built-in HashOf matcher' do
    validator = subject.HashOf(Symbol => Integer)
    expect(validator).to be === {a: 2, b:2}
  end

  it 'raises ArgumentError if the HashOf argument is wrong' do
    expect { subject.HashOf({a: 1, b: 2}) }.to raise_error(ArgumentError,
      "HashOf() takes a hash with one key and one value",
    )
  end

  it 'has a built-in RangeOf matcher' do
    validator = subject.RangeOf(Integer)
    expect(validator).to be === (1..10)
  end

  it 'has a built-in ArrayCoercer coercer' do
    coercer = subject.ArrayCoercer(:to_i.to_proc)
    expect(coercer.(%w(1 2 3))).to eq([1, 2, 3])
  end

  it 'provides a way to define methods whose names are invalid Ruby syntax' do
    subject.def_attr(:else)
    expect(subject.__attributes.first.name).to eq(:else)
  end

  it "produces a frozen recipe with DSL.run" do
    recipe = described_class.run { whatever }

    expect(recipe).to be_a(ValueSemantics::Recipe)
    expect(recipe).to be_frozen
    expect(recipe.attributes).to be_frozen
    expect(recipe.attributes.first).to be_frozen
    expect(recipe.attributes.first.name).to eq(:whatever)
  end

  it 'allows attributes to end with punctuation' do
    subject.qmark?
    subject.bang!
    expect(subject.__attributes.map(&:name)).to eq([:qmark?, :bang!])
  end

  it 'does not return anything when defining attributes' do
    expect(subject.foo).to be(nil)
  end
end
