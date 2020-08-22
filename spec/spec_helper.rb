require "bundler/setup"
require "delegate"
require "super_diff/rspec"
require "value_semantics"
require "byebug"

module SpecHelperMethods
  def with_constant(const_name, const_value)
    Object.const_set(const_name, const_value)
    yield
  ensure
    Object.send(:remove_const, const_name)
  end
end

RSpec.configure do |config|
  config.include SpecHelperMethods

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
