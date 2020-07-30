RSpec.describe ValueSemantics do
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
end
