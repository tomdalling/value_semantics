RSpec.describe ValueSemantics::Attribute do
  context 'defined with no options in particular' do
    subject { described_class.define(:whatever) }

    it 'raises if attempting to use missing default attribute' do
      expect { subject.default_generator.call }.to raise_error(
        "Attribute does not have a default value"
      )
    end

    it 'has default attributes' do
      expect(subject).to have_attributes(
        name: :whatever,
        validator: be(ValueSemantics::Anything),
        coercer: nil,
        default_generator: be(ValueSemantics::Attribute::NO_DEFAULT_GENERATOR),
      )
    end

    it { is_expected.to be_frozen }
    it { is_expected.not_to be_optional }
  end

  context 'initialized with no options in particular' do
    subject { described_class.new(name: :whatever) }

    it 'has default attributes' do
      expect(subject).to have_attributes(
        name: :whatever,
        validator: be(ValueSemantics::Anything),
        coercer: nil,
        default_generator: be(ValueSemantics::Attribute::NO_DEFAULT_GENERATOR),
      )
    end
  end

  context 'with a name ending in "?"' do
    subject { described_class.new(name: :x?) }

    it 'does not include the "?" in the instance variable name' do
      is_expected.to have_attributes(instance_variable: '@x')
    end
  end

  context 'with a name ending in "!"' do
    subject { described_class.new(name: :x!) }

    it 'does not include the "!" in the instance variable name' do
      is_expected.to have_attributes(instance_variable: '@x')
    end
  end

  context 'with a string name' do
    subject { described_class.new(name: 'x') }

    it 'converts the string to a symbol' do
      is_expected.to have_attributes(name: :x)
    end
  end

  context 'defined with a validator' do
    subject { described_class.define(:x, Integer) }

    it 'uses the validator in `validate?`' do
      expect(subject.validate?(5)).to be(true)
      expect(subject.validate?(:x)).to be(false)
    end
  end

  context 'defined with a `true` coercer' do
    subject { described_class.define(:x, coerce: true) }

    it 'calls a class method to do coercion' do
      klass = double
      allow(klass).to receive(:coerce_x).with(5).and_return(66)
      expect(subject.coerce(5, klass)).to eq(66)
    end
  end

  context 'defined with a callable coercer' do
    subject { described_class.define(:x, coerce: ->(v) { v + 100 }) }

    it 'calls the coercer with the given value' do
      expect(subject.coerce(1, nil)).to eq(101)
    end
  end

  context 'defined with a default' do
    subject { described_class.define(:x, default: 88) }

    it { is_expected.to be_optional }

    it 'returns the default value from default_generator' do
      expect(subject.default_generator.()).to eq(88)
    end
  end

  context 'defined with a default generator' do
    subject { described_class.define(:x, default_generator: ->() { 77 }) }

    it { is_expected.to be_optional }

    it 'sets default_generator' do
      expect(subject.default_generator.()).to eq(77)
    end
  end

  context 'defined with both a default and a default generator' do
    subject { described_class.define(:x, default: 5, default_generator: 5) }

    it 'raises an error' do
      expect { subject }.to raise_error(ArgumentError,
        "Attribute `x` can not have both a `:default` and a `:default_generator`"
      )
    end
  end

  context 'deprecated #determine_from!' do
    subject do
      described_class.new(
        name: :x,
        validator: Integer,
        **attrs,
      )
    end
    let(:attrs) { {} }
    class Penguin
      def self.coerce_x(x)
        x * 2
      end
    end

    it 'returns a [name, value] tuple on success' do
      expect(subject.determine_from!({ x: 3 }, Penguin)).to eq([:x, 3])
    end

    it 'raises MissingAttributes if the attr cant be found' do
      expect { subject.determine_from!({}, Penguin) }.to raise_error(
        ValueSemantics::MissingAttributes,
        'Attribute `Penguin#x` has no value',
      )
    end

    it 'raises InvalidValue when a validator fails' do
      expect { subject.determine_from!({ x: 'no' }, Penguin) }.to raise_error(
        ValueSemantics::InvalidValue,
        'Attribute `Penguin#x` is invalid: "no"',
      )
    end

    context 'with a default_generator' do
      before { attrs[:default_generator] = ->(){ 100 } }

      it 'calls the default_generator' do
        expect(subject.determine_from!({}, Penguin)).to eq([:x, 100])
      end
    end

    context 'with coercer: true' do
      before { attrs[:coercer] = true }

      it 'calls the coercion class method' do
        expect(subject.determine_from!({x: 4}, Penguin)).to eq([:x, 8])
      end
    end
  end
end
