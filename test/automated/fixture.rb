require_relative '../test_init'

class Person
  include ValueSemantics.for_attributes {
    name String
    age Integer
  }
end

TestBench.context ValueSemantics::Fixture do
  def capture_assertion(&block)
    ftf_class = Class.new do
      include TestBench::Fixture

      def initialize(block)
        @block = block
      end

      def call
        fixture(ValueSemantics::Fixture,
          value_class: Person,
          valid_attrs: { name: "Jimmy", age: 5 },
        ) do |f|
          test "the_one_test" do
            @block.(f)
          end
        end
      end
    end

    ftf = ftf_class.new(block)
    ftf.()

    session = ftf.test_session
    detail 'Details: ' + session.output.detail_records.map(&:data).inspect

    session
  end

  def assert_passes(caller_location: nil, &block)
    caller_location ||= caller_locations.first

    session = capture_assertion(&block)
    assert(session.test_passed?('the_one_test'), caller_location:caller_location)
  end

  def assert_fails(caller_location: nil, &block)
    caller_location ||= caller_locations.first

    session = capture_assertion(&block)
    assert(session.test_failed?('the_one_test'), caller_location:caller_location)
  end

  def assert_detail(session, detail_text, caller_location: nil, &block)
    caller_location ||= caller_locations.first

    detail "Expected detail: #{detail_text}"
    assert(session.detail?(detail_text), caller_location: caller_location)
  end

  context '#assert_attrs' do
    test 'passes when the attr is valid' do
      assert_passes do
        _1.assert_attrs(name: "Jimmy")
      end
    end

    test 'fails when the attr is invalid' do
      assert_fails do
        _1.assert_attrs(name: 5)
      end
    end

    test 'tests all elements of all arguments' do
      assert_passes do
        _1.assert_attrs({ name: '', age: 0 }, { age: 10 })
      end

      assert_fails do
        _1.assert_attrs({ name: '', age: 0 }, { age: 'x' })
      end
    end

    test 'includes detail about each attribute being tested' do
      session = capture_assertion { _1.assert_attrs(name: "William") }
      assert_detail(session, 'Person#with should accept: {:name=>"William"}')
      assert_detail(session, 'Person.new should accept: {:name=>"William"}')
    end
  end

  context '#refute_attrs' do
    test 'passes when the attr is invalid' do
      assert_passes do
        _1.refute_attrs(name: 5)
      end
    end

    test 'fails when the attr is valid' do
      assert_fails do
        _1.refute_attrs(name: 'sss')
      end
    end

    test 'tests all elements of all arguments' do
      assert_passes do
        _1.refute_attrs({ name: 5, age: 'x' }, { name: [] })
      end

      assert_fails do
        _1.refute_attrs({ name: 5, age: 'x' }, { name: 'hhh' })
      end
    end

    test 'includes detail about each attribute' do
      session = capture_assertion { _1.refute_attrs(name: "Jim") }
      assert_detail(session, 'Person#with should REJECT: {:name=>"Jim"}')
      assert_detail(session, 'Person.new should REJECT: {:name=>"Jim"}')
    end
  end

  context '#assert_coerces'
end
