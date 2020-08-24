# Only works in Ruby 2.6+
RSpec.describe ValueSemantics::RangeOf do
  subject { described_class.new(Integer) }

  it 'matches beginless ranges' do
    is_expected.to be === (1..)
  end

  it 'matches endless ranges' do
    is_expected.to be === (..10)
  end
end
