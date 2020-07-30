RSpec.describe ValueSemantics do
  describe ValueSemantics::Either do
    subject { described_class.new([Integer, String]) }

    it 'matches any of the subvalidators' do
      is_expected.to be === 5
      is_expected.to be === 'hello'
    end

    it 'does not match anything else' do
      is_expected.not_to be === nil
      is_expected.not_to be === [1,2,3]
    end

    it 'is frozen' do
      is_expected.to be_frozen
    end
  end
end
