RSpec.describe ValueSemantics::HashOf do
  subject { described_class.new(Integer, Float) }

  it 'matches empty hashes' do
    is_expected.to be === {}
  end

  it 'matches hashes where the key and value validators also match' do
    is_expected.to be === { 1 => 1.2, 2 => 2.4 }
  end

  it 'does not match hashes where the key validator does not match' do
    expect(subject === { a: 1.2 }).to be(false)
  end

  it 'does not match hashes where the value validator does not match' do
    expect(subject === { 1 => 'no' }).to be(false)
  end

  it 'does not match anything else' do
    expect(subject === nil).to be(false)
    expect(subject === 'hello').to be(false)
    expect(subject === [1, 1.2, 2, 2.4]).to be(false)
    expect(subject === [[1, 1.2], [2, 2.4]]).to be(false)
  end

  it 'is frozen' do
    is_expected.to be_frozen
  end
end
