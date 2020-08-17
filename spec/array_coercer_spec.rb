RSpec.describe ValueSemantics do
  describe ValueSemantics::ArrayCoercer do
    it 'is frozen' do
      is_expected.to be_frozen
    end

    it 'calls #to_a on objects that respond to it' do
      expect(subject.(double(to_a: ['yep']))).to eq(['yep'])
    end

    it 'does not affect objects that dont respond to #to_a' do
      expect(subject.(111)).to eq(111)
    end

    context 'with an element coercer' do
      subject { described_class.new(:join.to_proc) }

      it 'applies the element coercer to each element' do
        expect(subject.({a:1, b:2})).to eq(['a1', 'b2'])
      end
    end
  end
end
