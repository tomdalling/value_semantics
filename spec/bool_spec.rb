RSpec.describe ValueSemantics do
  describe ValueSemantics::Bool do
    it 'matches true and false' do
      is_expected.to be === true
      is_expected.to be === false
    end

    it 'does not match nil or other values' do
      is_expected.not_to be === nil
      is_expected.not_to be === 5
    end
  end
end
