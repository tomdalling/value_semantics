RSpec.describe ValueSemantics do
  describe '.monkey_patch!' do

    after(:each) do
      undo_monkey_patch! if monkey_patched?
      Object.send(:remove_const, :Munkey) if Object.const_defined?(:Munkey)
    end

    def monkey_patched?
      Class.respond_to?(:value_semantics, true)
    end

    def undo_monkey_patch!
      Class.class_eval do
        public :value_semantics
        remove_method :value_semantics
      end
    end

    def define_munkey!
      eval <<~END_CODE
        class Munkey
          value_semantics do
            age Integer
          end
        end
      END_CODE
    end

    specify "we can patch an unpatch reliably" do
      2.times do
        expect(monkey_patched?).to be_falsey
        ValueSemantics.monkey_patch!
        expect(monkey_patched?).to be_truthy
        undo_monkey_patch!
        expect(monkey_patched?).to be_falsey
      end
    end

    shared_examples "monkey-patched `value_semantics` class method" do
      it "is disabled by default" do
        expect { define_munkey! }
          .to raise_error(NameError, /undefined method `value_semantics'/)
      end

      context 'when enabled' do
        before do
          install_monkey_patch!
        end

        it "makes `value_semantics` class method available to all classes" do
          define_munkey!
          expect(Munkey.new(age: 1)).to have_attributes(age: 1)
        end

        it "is class-private" do
          expect { Integer.value_semantics }
            .to raise_error(NoMethodError, /private method `value_semantics' called/)
        end

        it "is replaced by the class-public recipe getter after being called" do
          define_munkey!
          expect(Munkey.value_semantics).to be_a(ValueSemantics::Recipe)
        end

        it "can not be called twice" do
          define_munkey!
          expect { define_munkey! }.to raise_error(
            RuntimeError,
            '`Munkey` has already included ValueSemantics',
          )
        end

        it "does not affect modules" do
          expect do
            Module.new do
              extend self
              value_semantics do
                name String
              end
            end
          end.to raise_error(NameError, /undefined method `value_semantics'/)
        end

        it "does nothing if enabled multiple times" do
          3.times { install_monkey_patch! }
          define_munkey!

          expect(Munkey.new(age: 99)).to have_attributes(age: 99)
        end
      end
    end

    context 'using `ValueSemantics.monkey_patch!`' do
      include_examples "monkey-patched `value_semantics` class method"

      def install_monkey_patch!
        ValueSemantics.monkey_patch!
      end
    end

    context "using `require 'value_semantics/monkey_patched'`" do
      include_examples "monkey-patched `value_semantics` class method"

      def install_monkey_patch!
        # allow `require` to load the file multiple times
        $LOADED_FEATURES.reject! do |path|
          path.end_with?('value_semantics/monkey_patched.rb')
        end

        require 'value_semantics/monkey_patched'
      end
    end

  end
end
