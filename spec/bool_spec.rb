RSpec.describe ValueSemantics::Bool do
  it 'matches true and false' do
    is_expected.to be === true
    is_expected.to be === false
  end

  it 'does not match nil or other values' do
    expect(subject === nil).to be(false)
    expect(subject === 5).to be(false)
  end
end
