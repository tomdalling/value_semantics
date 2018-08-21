# ValueType

Immutable struct-like value classes, with light-weight validation and coercion.

These are intended for internal use, as opposed to validating user input like ActiveRecord.
Invalid or missing attributes cause an exception intended for developers,
not an error message intended for the user.

## Basic Usage

```ruby
require 'value_type'

class Person < ValueType
  def_attributes do
    name
    age default: 31
  end
end

tom = Person.new(name: 'Tom')


#
# Read-only attributes
#
tom.name  #=> "Tom"
tom.age  #=> 31


#
# Convert to Hash
#
tom.to_h  #=> { :name => "Tom", :age => 31 }


#
# Non-destructive updates
#
old_tom = tom.with(age: 99)

old_tom  #=> #<Person name="Tom" age=99>
tom      #=> #<Person name="Tom" age=31> (unchanged)


#
# Equality
#
other_tom = Person.new(name: 'Tom', age: 31)

tom == other_tom  #=> true
tom.eql?(other_tom)  #=> true
tom.hash == other_tom.hash  #=> true
```


## Validation (Types)

Validators are objects that implement the `===` method,
which means you can use `Class` objects (like `String`) and also `Regexp` objects:

```ruby
class Person < ValueType
  def_attributes do
    name String
    birthday /\d\d\d\d-\d\d-\d\d/
  end
end

Person.new(name: 'Tom', ...)  # works
Person.new(name: 5, ...)
#=> ArgumentError:
#=>     Value for attribute 'name' is not valid: 5

Person.new(birthday: "1970-01-01", ...)  # works
Person.new(birthday: "hello", ...)
#=> ArgumentError:
#=>     Value for attribute 'birthday' is not valid: "hello"
```

A custom validator might look something like this:

```ruby
module Odd
  def self.===(value)
    value.odd?
  end
end

class Person < ValueType
  def_attributes do
    age Odd
  end
end

Person.new(age: 9)  # works
Person.new(age: 8)
#=> ArgumentError:
#=>     Value for attribute 'age' is not valid: 8
```

Default attribute values also pass through validation.


## Coercion

Coercion blocks can convert invalid values into valid ones, where possible.

```ruby
class Server < ValueType
  def_attributes do
    address IPAddr do |value|
      if value.is_a?(String)
        IPAddr.new(value)
      else
        value
      end
    end
  end
end

Server.new(address: '127.0.0.1')  # works
Server.new(address: IPAddr.new('127.0.0.1'))  # works
Server.new(address: 42)
#=> ArgumentError:
#=>     Value for attribute 'address' is not valid: 42
```

If coercion is not possible, the value is to returned unchanged, allowing the validator to fail.
Another option is to raise an error within the coercion block.

Coercion happens before validation.
Default attribute values also pass through coercion.

## All Together

```ruby
class Coordinate < ValueType
  def_attributes do
    latitude Float, default: 0 { |value| value.to_f }
    longitude Float, default: 0 { |value| value.to_f }
  end
end

Coordinate.new(longitude: "123")
#=> #<Coordinate latitude=0.0 longitude=123.0>
```


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'value_type'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install value_type


## Contributing

Bug reports and pull requests are welcome on GitHub at:
https://github.com/tomdalling/value_type


## License

The gem is available as open source under the terms of the [MIT
License](http://opensource.org/licenses/MIT).

