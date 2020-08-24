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

    it 'is frozen' do
      is_expected.to be_frozen
    end

    it 'returns the :missing error type if it cant be determined from a hash of attribute values' do
      _, error_type = subject.determine_from({})
      expect(error_type).to be(:missing)
    end
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

    it 'determines values from a hash' do
      expect(subject.determine_from({x: 5})).to eq([5, nil])
    end

    it 'returns an exception if the determined value is invalid' do
      _, error_type = subject.determine_from({x: 'no'})
      expect(error_type).to be(:invalid)
    end
  end

  context 'defined with a `true` coercer' do
    subject { described_class.define(:x, coerce: true) }

    it 'calls a class method to do coercion' do
      klass = double
      allow(klass).to receive(:coerce_x).with(5).and_return(66)
      expect(subject.determine_from({x: 5}, value_class: klass)).to eq([66, nil])
    end
  end

  context 'defined with a callable coercer' do
    subject { described_class.define(:x, coerce: ->(v) { v + 100 }) }

    it 'calls the coercer with the given value' do
      expect(subject.determine_from({x: 1})).to eq([101, nil])
    end
  end

  context 'defined with a default' do
    subject { described_class.define(:x, default: 88) }

    it 'uses the default when no value is provided' do
      expect(subject.determine_from({})).to eq([88, nil])
    end
  end

  context 'defined with a default generator' do
    subject { described_class.define(:x, default_generator: ->() { 77 }) }

    it 'calls the default generator when no value is provided' do
      expect(subject.determine_from({})).to eq([77, nil])
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

  context 'deprecated methods' do
    context '#determine_from!' do
      subject { described_class.new(name: :x, validator: Integer) }

      it 'returns a [name, value] tuple on success' do
        expect(subject.determine_from!({ x: 3 }, Array)).to eq([:x, 3])
      end

      it 'raises MissingAttributes if the attr cant be found' do
        expect { subject.determine_from!({}, Array) }.to raise_error(
          ValueSemantics::MissingAttributes,
          'Attribute `Array#x` has no value',
        )
      end

      it 'raises InvalidValue when a validator fails' do
        expect { subject.determine_from!({ x: 'no' }, Array) }.to raise_error(
          ValueSemantics::InvalidValue,
          'Attribute `Array#x` is invalid: "no"',
        )
      end

      # NOTE: this test is just to make mutant happy
      it 'raises a debugging error if the error type is unexpected' do
        subject = Class.new(described_class) do
          def determine_from(*)
            [nil, :unexpected_type]
          end
        end.new(name: :x)

        expect { subject.determine_from!(nil, nil) }.to raise_error(
          "Unhandled error type: :unexpected_type"
        )
      end
    end
  end
end
