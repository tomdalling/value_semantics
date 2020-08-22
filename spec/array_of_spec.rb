RSpec.describe ValueSemantics::ArrayOf do
  subject { described_class.new(Integer) }

  it 'uses the subvalidator for each element in the array' do
    is_expected.to be === [1,2,3]
    is_expected.to be === []
  end

  it 'does not match anything else' do
    is_expected.not_to be === nil
    is_expected.not_to be === 'hello'
    is_expected.not_to be === %i(1 2 3)
    is_expected.not_to be === Set.new([1, 2, 3])
  end

  it 'is frozen' do
    is_expected.to be_frozen
  end
end
