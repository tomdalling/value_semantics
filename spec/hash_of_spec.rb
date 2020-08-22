RSpec.describe ValueSemantics::HashOf do
  subject { described_class.new(Integer, Float) }

  it 'matches empty hashes' do
    is_expected.to be === {}
  end

  it 'matches hashes where the key and value validators also match' do
    is_expected.to be === { 1 => 1.2, 2 => 2.4 }
  end

  it 'does not match hashes where the key validator does not match' do
    is_expected.not_to be === { a: 1.2 }
  end

  it 'does not match hashes where the value validator does not match' do
    is_expected.not_to be === { 1 => 'no' }
  end

  it 'does not match anything else' do
    is_expected.not_to be === nil
    is_expected.not_to be === 'hello'
    is_expected.not_to be === [1, 1.2, 2, 2.4]
    is_expected.not_to be === [[1, 1.2], [2, 2.4]]
  end

  it 'is frozen' do
    is_expected.to be_frozen
  end
end
