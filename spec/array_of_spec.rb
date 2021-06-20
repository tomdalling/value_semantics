require 'set'

RSpec.describe ValueSemantics::ArrayOf do
  subject { described_class.new(Integer) }

  it 'uses the subvalidator for each element in the array' do
    is_expected.to be === [1,2,3]
    is_expected.to be === []
  end

  it 'does not match anything else' do
    expect(subject === nil).to be(false)
    expect(subject === 'hello').to be(false)
    expect(subject === %i(1 2 3)).to be(false)
    expect(subject === Set.new([1, 2, 3])).to be(false)
  end

  it 'is frozen' do
    is_expected.to be_frozen
  end
end
