[![Build Status](https://travis-ci.org/tomdalling/value_semantics.svg?branch=master)](https://travis-ci.org/tomdalling/value_semantics)

ValueSemantics
==============

Create value classes quickly, with all the [conventions of a good value object](https://github.com/zverok/good-value-object).

Generates modules that provide value semantics for a given set of attributes.
Provides the behaviour of an immutable struct-like value class,
with light-weight validation and coercion.

These are intended for internal use, as opposed to validating user input like ActiveRecord.
Invalid or missing attributes cause an exception intended for developers,
not an error message intended for the user.


Basic Usage
-----------

```ruby
require 'value_semantics'

class Person
  include ValueSemantics.for_attributes {
    name
    age default: 31
  }
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

The curly bracket syntax used with `ValueSemantics.for_attributes` is, unfortunately,
mandatory due to Ruby's precedence rules.
The `do`/`end` syntax will not work unless you surround the whole thing with parenthesis.


Validation (Types)
------------------

Each attribute may optionally have a validator, to check that values are correct.

Validators are objects that implement the `===` method,
which means you can use `Class` objects (like `String`),
and also things like regular expressions.
Anything that you can use in a `case`/`when` expression will work.

```ruby
class Person
  include ValueSemantics.for_attributes {
    name String
    birthday /\d\d\d\d-\d\d-\d\d/
  }
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


### Built-in Validators

The ValueSemantics DSL comes with a small number of built-in validators,
for common situations:

```ruby
class LightSwitch
  include ValueSemantics.for_attributes {

    # Boolean: only allows `true` or `false`
    on? Boolean()

    # ArrayOf: validates elements in an array
    light_ids ArrayOf(Integer)

    # Either: value must match at least one of a list of validators
    color Either(Integer, String, nil)

    # these validators are composable
    wierd_attr Either(Boolean(), ArrayOf(Boolean()))
  }
end

LightSwitch.new(
  on?: true,
  light_ids: [11, 12, 13],
  color: "#FFAABB",
  wierd_attr: [true, false, true, true],
)
```


### Custom Validators

A custom validator might look something like this:

```ruby
module Odd
  def self.===(value)
    value.odd?
  end
end

class Person
  include ValueSemantics.for_attributes {
    age Odd
  }
end

Person.new(age: 9)  # works
Person.new(age: 8)
#=> ArgumentError:
#=>     Value for attribute 'age' is not valid: 8
```

Default attribute values also pass through validation.


Coercion
--------

Coercion allows non-standard or "convenience" values to be converted into
proper, valid values, where possible.

For example, an object with an `IPAddr` attribute may allow string values,
which are then coerced into `IPAddr` objects.

To implement coercion, define a class method called `coerce_#{attr}` which
accepts a raw value, and returns the coerced value.

```ruby
class Server
  include ValueSemantics.for_attributes {
    address IPAddr
  }

  def self.coerce_address(value)
    if value.is_a?(String)
      IPAddr.new(value)
    else
      value
    end
  end
end

Server.new(address: '127.0.0.1')
#=> #<Server address=#<IPAddr: IPv4:127.0.0.1/255.255.255.255>>

Server.new(address: IPAddr.new('127.0.0.1'))
#=> #<Server address=#<IPAddr: IPv4:127.0.0.1/255.255.255.255>>

Server.new(address: 42)
#=> ArgumentError:
#=>     Value for attribute 'address' is not valid: 42
```

If coercion is not possible, you can return the value unchanged,
allowing the validator to fail.
Another option is to raise an error within the coercion method.

Coercion happens before validation.
Default attribute values also pass through coercion.


## All Together

```ruby
class Person
  include ValueSemantics.for_attributes {
    name String, default: "Anon Emous"
    birthday Either(Date, nil)
  }

  def self.coerce_birthday(value)
    if value.is_a?(String)
      Date.parse(value)
    else
      value
    end
  end
end

Person.new(name: "Tom", birthday: "2020-12-25")
#=> #<Person name="Tom" birthday=#<Date: 2020-12-25 ((2459209j,0s,0n),+0s,2299161j)>>

Person.new(birthday: Date.today)
#=> #<Person name="Anon Emous" birthday=#<Date: 2018-09-04 ((2458366j,0s,0n),+0s,2299161j)>>

Person.new(birthday: nil)
#=> #<Person name="Anon Emous" birthday=nil>
```


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'value_semantics'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install value_semantics


## Contributing

Bug reports and pull requests are welcome on GitHub at:
https://github.com/tomdalling/value_semantics


## License

The gem is available as open source under the terms of the [MIT
License](http://opensource.org/licenses/MIT).

