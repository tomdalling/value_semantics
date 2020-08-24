RSpec.describe ValueSemantics::ValueObjectCoercer do
  subject { described_class.new(Seal) }
  class Seal
    include ValueSemantics.for_attributes {
      name String
      d Integer, default: 1
    }
  end

  it "converts hashes to an instance of the given value class" do
    expect(subject.(name: 'Jim')).to eq(Seal.new(name: 'Jim', d: 1))
  end

  it "allows extraneous keys" do
    expect(subject.(name: 'x', age: 10)).to eq(Seal.new(name: 'x', d: 1))
  end

  it "allows keys to be strings" do
    expect(subject.('name' => 'y')).to eq(Seal.new(name: 'y', d: 1))
  end

  it "takes symbol keys before string keys" do
    expect(subject.(name: 'a', 'name' => 'b')).to eq(Seal.new(name: 'a', d: 1))
  end

  it "allows hashable objects" do
    hashable = double(to_h: { 'name' => 'z' })
    expect(subject.(hashable)).to eq(Seal.new(name: 'z', d: 1))
  end

  it "ignores non-hashable objects" do
    non_hashable = double
    expect(subject.(non_hashable)).to equal(non_hashable)
  end
end
