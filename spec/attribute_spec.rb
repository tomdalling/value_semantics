RSpec.describe ValueSemantics do
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
end
