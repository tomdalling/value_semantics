RSpec.describe ValueSemantics do
  describe ValueSemantics::Struct do
    subject do
      described_class.new do
        attr1 Array, default: [4,5,6]
        attr2
      end
    end

    it "returns a value class, like Struct.new does" do
      expect(subject).to be_a(Class)
      expect(subject.value_semantics).to be_a(ValueSemantics::Recipe)
      expect(subject.new(attr2: nil)).to be_a(subject)
    end

    it "makes instances that work like normal ValueSemantics objects" do
      instance = subject.new(attr2: 2)
      expect(instance.attr1).to eq([4,5,6])
      expect(instance.attr2).to eq(2)
    end
  end
end
