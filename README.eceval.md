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
#=>

Person.new(birthday: Date.today)
#=>

Person.new(birthday: nil)
#=>
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
tom.name    #=>
tom[:name]  #=>

# Convert to Hash
tom.to_h  #=>

# Non-destructive updates
tom.with(age: 99) #=>
tom # (unchanged) #=>

# Equality
other_tom = Person.new(name: 'Tom', age: 31)
tom == other_tom  #=>
tom.eql?(other_tom)  #=>
tom.hash == other_tom.hash  #=>

# Ruby 2.7+ pattern matching
case tom
in name: "Tom", age:
  puts age
end
# outputs:
```


Convenience (Monkey Patch)
--------------------------

There is a shorter way to define value attributes:

```ruby
  require 'value_semantics/monkey_patched'

  class Monkey
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
#=>
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

Person.new(name: 'Tom', birthday: '2000-01-01')  # works
Person.new(name: 5,     birthday: '2000-01-01')
#=> !!!

Person.new(name: 'Tom', birthday: "1970-01-01")  # works
Person.new(name: 'Tom', birthday: "hello")
#=> !!!
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

    # HashOf: validates keys/values of a homogeneous hash
    toggle_stats HashOf(Symbol => Integer)

    # Either: value must match at least one of a list of validators
    color Either(Integer, String, nil)

    # these validators are composable
    wierd_attr Either(Bool(), ArrayOf(Bool()))
  }
end

LightSwitch.new(
  on?: true,
  light_ids: [11, 12, 13],
  toggle_stats: { day: 42, night: 69 },
  color: "#FFAABB",
  wierd_attr: [true, false, true, true],
)
#=>
```


### Custom Validators

A custom validator might look something like this:

```ruby
module DottedQuad
  def self.===(value)
    value.split('.').all? do |part|
      ('0'..'255').cover?(part)
    end
  end
end

class Server
  include ValueSemantics.for_attributes {
    address DottedQuad
  }
end

Server.new(address: '127.0.0.1')
#=>

Server.new(address: '127.0.0.999')
#=> !!!
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
#=>

Document.new(path: Pathname.new('~/Documents/whatever.doc'))
#=>

Document.new(path: 42)
#=> !!!
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


## Nesting

It is fairly common to nest value objects inside each other. This
works as expected, but coercion is not automatic.

For nested coercion, use the `.coercer` class method that
ValueSemantics provides. It returns a coercer object that accepts
strings for attribute names, and will ignore attributes that the value
class does not define, instead of raising an error.

This works well in combination with `ArrayCoercer`.

```ruby
class CrabClaw
  include ValueSemantics.for_attributes {
    size Either(:big, :small)
  }
end

class Crab
  include ValueSemantics.for_attributes {
    left_claw CrabClaw, coerce: CrabClaw.coercer
    right_claw CrabClaw, coerce: CrabClaw.coercer
  }
end

class Ocean
  include ValueSemantics.for_attributes {
    crabs ArrayOf(Crab), coerce: ArrayCoercer(Crab.coercer)
  }
end

ocean = Ocean.new(
  crabs: [
    {
      'left_claw' => { 'size' => :small },
      'right_claw' => { 'size' => :small },
      voiced_by: 'Samuel E. Wright',  # this attr will be ignored
    }, {
      'left_claw' => { 'size' => :big },
      'right_claw' => { 'size' => :big },
    }
  ]
)

ocean.crabs.first #=>
ocean.crabs.first.right_claw.size #=>
```


## ValueSemantics::Struct

This is a convenience for making a new class and including ValueSemantics in
one step, similar to how `Struct` works from the Ruby standard library. For
example:

```ruby
Pigeon = ValueSemantics::Struct.new do
  name String, default: "Jannie"
end

Pigeon.new.name #=>
```


## Known Issues

Some valid attribute names result in invalid Ruby syntax when using the DSL.
In these situations, you can use the DSL method `def_attr` instead.

For example, if you want an attribute named `then`:

```ruby
# Can't do this:
class Conditional
  include ValueSemantics.for_attributes {
    then String
    else String
  }
end
#=> !!!


# This will work
class Conditional
  include ValueSemantics.for_attributes {
    def_attr :then, String
    def_attr :else, String
  }
end
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

