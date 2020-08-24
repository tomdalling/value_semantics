RSpec.describe ValueSemantics::Either do
  subject { described_class.new([Integer, String]) }

  it 'matches any of the subvalidators' do
    is_expected.to be === 5
    is_expected.to be === 'hello'
  end

  it 'does not match anything else' do
    expect(subject === nil).to be(false)
    expect(subject === [1,2,3]).to be(false)
  end

  it 'is frozen' do
    is_expected.to be_frozen
  end
end
