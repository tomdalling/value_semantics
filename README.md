[![Gem Version](https://badge.fury.io/rb/value_semantics.svg)](https://badge.fury.io/rb/value_semantics)
[![Build Status](https://travis-ci.org/tomdalling/value_semantics.svg?branch=master)](https://travis-ci.org/tomdalling/value_semantics)
![Mutation Coverage](https://img.shields.io/badge/mutation%20coverage-to%20the%20MAX-brightgreen.svg)

ValueSemantics
==============

A gem for making value classes.

Generates modules that provide [conventional value semantics](https://github.com/zverok/good-value-object) for a given set of attributes.
The behaviour is similar to an immutable `Struct` class,
plus extensible, lightweight validation and coercion.

These are intended for internal use, as opposed to validating user input like ActiveRecord.
Invalid or missing attributes cause an exception for developers,
not an error message intended for application users.

See:

 - The [announcement blog post][blog post] for some of the rationale behind the gem
 - [RubyTapas episode #584][rubytapas] for an example usage scenario
 - The [API documentation](https://rubydoc.info/gems/value_semantics)
 - Some [discussion on Reddit][reddit]

[blog post]: https://www.rubypigeon.com/posts/value-semantics-gem-for-making-value-classes/
[rubytapas]: https://www.rubytapas.com/2019/07/09/from-hash-to-value-object/
[reddit]: https://www.reddit.com/r/ruby/comments/akz4fs/valuesemanticsa_gem_for_making_value_classes/


Defining and Creating Value Objects
-----------------------------------

```ruby
class Person
  include ValueSemantics.for_attributes {
    name String, default: "Anon Emous"
    birthday Either(Date, nil), coerce: true
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

Value objects are typically initialized with keyword arguments or a `Hash`, but
will accept any object that responds to `#to_h`.

The curly bracket syntax used with `ValueSemantics.for_attributes` is,
unfortunately, mandatory due to Ruby's precedence rules. For a shorter
alternative method that works better with `do`/`end`, see [Convenience (Monkey
Patch)](#convenience-monkey-patch) below.


Using Value Objects
-------------------

```ruby
require 'value_semantics'

class Person
  include ValueSemantics.for_attributes {
    name
    age default: 31
  }
end

tom = Person.new(name: 'Tom')


# Read-only attributes
tom.name  #=> "Tom"
tom.age  #=> 31


# Convert to Hash
tom.to_h  #=> { :name => "Tom", :age => 31 }


# Non-destructive updates
old_tom = tom.with(age: 99)
old_tom  #=> #<Person name="Tom" age=99>
tom      #=> #<Person name="Tom" age=31> (unchanged)


# Equality
other_tom = Person.new(name: 'Tom', age: 31)
tom == other_tom  #=> true
tom.eql?(other_tom)  #=> true
tom.hash == other_tom.hash  #=> true


# Ruby 2.7+ pattern matching
case tom
in name: "Tom", age:
  puts age  # outputs: 31
end
```


Convenience (Monkey Patch)
--------------------------

There is a shorter way to define value attributes:

```ruby
  class Person
    value_semantics do
      name String
      age Integer
    end
  end
```

**This is disabled by default**, to avoid polluting every class with an extra
class method.

This convenience method can be enabled in two ways:

 1. Add a `require:` option to your `Gemfile` like this:

    ```ruby
    gem 'value_semantics', '~> 3.3', require: 'value_semantics/monkey_patched'
    ```

 2. Alternatively, you can call `ValueSemantics.monkey_patch!` somewhere early
    in the boot sequence of your code -- at the top of your script, for example,
    or `config/boot.rb` if it's a Rails project.

    ```ruby
    require 'value_semantics'
    ValueSemantics.monkey_patch!
    ```


Defaults
--------

Defaults can be specified in one of two ways:
the `:default` option, or the `:default_generator` option.

```ruby
class Cat
  include ValueSemantics.for_attributes {
    paws Integer, default: 4
    born_at Time, default_generator: ->{ Time.now }
  }
end

Cat.new
#=> #<Cat paws=4 born_at=2018-12-21 18:42:01 +1100>
```

The `default` option is a single value.

The `default_generator` option is a callable object, which returns a default value.
In the example above, `default_generator` is a lambda that returns the current time.

Only one of these options can be used per attribute.


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
    birthday /\d{4}-\d{2}-\d{2}/
  }
end

Person.new(name: 'Tom', ...)  # works
Person.new(name: 5, ...)
#=> ValueSemantics::InvalidValue:
#=>     Attribute `Person#name` is invalid: 5

Person.new(birthday: "1970-01-01", ...)  # works
Person.new(birthday: "hello", ...)
#=> ValueSemantics::InvalidValue:
#=>     Attribute 'Person#birthday' is invalid: "hello"
```


### Built-in Validators

The ValueSemantics DSL comes with a small number of built-in validators,
for common situations:

```ruby
class LightSwitch
  include ValueSemantics.for_attributes {

    # Bool: only allows `true` or `false`
    on? Bool()

    # ArrayOf: validates elements in an array
    light_ids ArrayOf(Integer)

    # Either: value must match at least one of a list of validators
    color Either(Integer, String, nil)

    # these validators are composable
    wierd_attr Either(Bool(), ArrayOf(Bool()))
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
#=> ValueSemantics::InvalidValue:
#=>     Attribute 'Person#age' is invalid: 8
```

Default attribute values also pass through validation.


Coercion
--------

Coercion allows non-standard or "convenience" values to be converted into
proper, valid values, where possible.

For example, an object with an `Pathname` attribute may allow string values,
which are then coerced into `Pathname` objects.

Using the option `coerce: true`,
coercion happens through a custom class method called `coerce_#{attr}`,
which takes the raw value as an argument, and returns the coerced value.

```ruby
require 'pathname'

class Document
  include ValueSemantics.for_attributes {
    path Pathname, coerce: true
  }

  def self.coerce_path(value)
    if value.is_a?(String)
      Pathname.new(value)
    else
      value
    end
  end
end

Document.new(path: '~/Documents/whatever.doc')
#=> #<Document path=#<Pathname:~/Documents/whatever.doc>>

Document.new(path: Pathname.new('~/Documents/whatever.doc'))
#=> #<Document path=#<Pathname:~/Documents/whatever.doc>>

Document.new(path: 42)
#=> ValueSemantics::InvalidValue:
#=>     Attribute 'Document#path' is invalid: 42
```

You can also use any callable object as a coercer.
That means, you could use a lambda:

```ruby
class Document
  include ValueSemantics.for_attributes {
    path Pathname, coerce: ->(value) { Pathname.new(value) }
  }
end
```

Or a custom class:

```ruby
class MyPathCoercer
  def call(value)
    Pathname.new(value)
  end
end

class Document
  include ValueSemantics.for_attributes {
    path Pathname, coerce: MyPathCoercer.new
  }
end
```

Or reuse an existing method:

```ruby
class Document
  include ValueSemantics.for_attributes {
    path Pathname, coerce: Pathname.method(:new)
  }
end
```

Coercion happens before validation.
If coercion is not possible, coercers can return the raw value unchanged,
allowing the validator to fail with a nice, descriptive exception.
Another option is to raise an error within the coercion method.

Default attribute values also pass through coercion.
For example, the default value could be a string,
which would then be coerced into an `Pathname` object.


## ValueSemantics::Struct

This is a convenience for making a new class and including ValueSemantics in
one step, similar to how `Struct` works from the Ruby standard library. For
example:

```ruby
Cat = ValueSemantics::Struct.new do
  name String, default: "Mittens"
end

Cat.new.name #=> "Mittens"
```


## Known Issues

Some valid attribute names result in invalid Ruby syntax when using the DSL.
In these situations, you can use the DSL method `def_attr` instead.

For example, if you want an attribute named `then`:

```ruby
include ValueSemantics.for_attributes {
  # !!! SyntaxError: syntax error, unexpected `then'
  then String, default: "whatever"

  # This will work:
  def_attr :then, String, default: "whatever"
}
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

Keep in mind that this gem aims to be as close to 100% backwards compatible as
possible.

I'm happy to accept PRs that:

 - Improve error messages for a better developer experience, especially those
   that support a TDD workflow.
 - Add new, helpful validators
 - Implement automatic freezing of value objects (must be opt-in)

## License

The gem is available as open source under the terms of the [MIT
License](http://opensource.org/licenses/MIT).

