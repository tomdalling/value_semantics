RSpec.describe ValueSemantics::HashCoercer do
  subject do
    described_class.new(
      key_coercer: ->(x) { x.to_sym },
      value_coercer: ->(x) { x.to_i },
    )
  end

  it { is_expected.to be_frozen }

  it 'coerces hash-like objects to hashes' do
    hashlike = double(to_h: {a: 1})
    expect(subject.(hashlike)).to eq({a: 1})
  end

  it 'returns non-hash-like objects, unchanged' do
    expect(subject.(5)).to eq(5)
  end

  it 'allows empty hashes' do
    expect(subject.({})).to eq({})
  end

  it 'coerces hash keys' do
    expect(subject.({'a' => 1})).to eq({a: 1})
  end

  it 'coerces hash values' do
    expect(subject.({a: '1'})).to eq({a: 1})
  end
end
