RSpec.describe ValueSemantics::RangeOf do
  subject { described_class.new(Integer) }

  it 'matches ranges using the given subvalidator' do
    is_expected.to be === (1..10)
  end

  it 'does not match ranges whose `begin` does not match the subvalidator' do
    expect(subject === (1.0..10)).to be(false)
  end

  it 'does not match ranges whose `end` does not match the subvalidator' do
    expect(subject === (1..10.0)).to be(false)
  end

  it 'does not match objects that are not ranges' do
    expect(subject === 'hello').to be(false)
  end
end
