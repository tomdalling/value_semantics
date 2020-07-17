RSpec.describe ValueSemantics do
  shared_examples 'pattern matching' do
    it 'deconstructs to a hash' do
      case subject
      in { name:, age: Integer => age }
        expect(name).to eq('Tom')
        expect(age).to eq(69)
      else
        fail "Hash deconstruction not implemented properly"
      end
    end
  end

  context 'class with ValueSemantics included' do
    subject do
      Class.new do
        include ValueSemantics.for_attributes {
          name String
          age Integer
        }
      end.new(name: 'Tom', age: 69)
    end

    include_examples 'pattern matching'
  end

  context 'ValueSemantics::Struct class' do
    subject do
      ValueSemantics::Struct.new do
        name String
        age Integer
      end.new(name: 'Tom', age: 69)
    end

    include_examples 'pattern matching'
  end
end
