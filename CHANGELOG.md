# Changelog

Notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.6.0] - 2020-09-01
### Added
- `RangeOf` built-in validator, for validating `Range` objects
- `HashCoercer` built-in coercer for homogeneous `Hash` objects
### Changed
- Optimised speed of value object initialization. It is now roughly 3x
  slower than that of a hand-written class, which is 2-3x faster than
  the previous version.

- Optimised memory allocation in object initialization. The happy path
  (no exceptions raised) only allocates a single array object, under
  normal circumstances. Extra allocations are likely caused by custom
  validators, coercers, and default generators.

- Exceptions raised when initialising a value object are now
  aggregated. Instead of telling you the problematic attributes one at
  a time, you will get a list of all offending attributes in the
  exception message. This applies to `MissingAttributes`,
  `InvalidValue` and `UnrecognizedAttributes`. These will probably be
  combined into a single exception in v4.0, so you can see all the
  initialization problems at once.

- The exceptions `ValueSemantics::MissingAttributes` and
  `ValueSemantics::InvalidValue` are now raised from inside
  `initialize`. They were previously raised from inside of
  `ValueSemantics::Attribute.determine_from!` which is an internal
  implementation detail that is basically gibberish to any developer
  reading it. The stack trace for this exception reads much better.

- The exception `ValueSemantics::UnrecognizedAttributes` is now raised
  instead of `ValueSemantics::MissingAttributes` in the situation
  where both exceptions would be raised. This makes it easier to debug
  the problem where you attempt to initialize a value object using a
  hash with string keys instead of symbol keys.

- The coercer returned from the `.coercer` class method is now
  smarter. It handles string keys, handles objects that can be
  converted to hashes.
### Deprecated
- `ValueSemantics::Attribute#determine_from!`. This was an internal
  implementation detail, which is no longer used internally. Use the
  `name`, `#coerce`, `#optional?`, `#default_generator` and
  `#validate?` methods directly if you want to extract an attribute
  from a hash.
- `ValueSemantics::NoDefaultError`. Use `Attribute#optional?` to check
  whether there is a default.



## [3.5.0] - 2020-08-17
### Added
- Square bracket attr reader like `person[:name]`
- `HashOf` built-in validator, similar to `ArrayOf`
- `.coercer` class method, to help when composing value objects
- `ArrayCoercer` DSL method, to help when composing value objects

## [3.4.0] - 2020-08-01
### Added
- Value objects can be instantiated from any object that responds to `#to_h`.
  Previously attributes were required to be given as a `Hash`.

- Added monkey patching for super-convenient attribute definitions. This is
  **not** available by default, and needs to be explicitly enabled with
  `ValueSemantics.monkey_patch!` or `require 'value_semantics/monkey_patched'`.

### Changed
- Improved exception messages for easier development experience

- Raises `ValueSemantics::InvalidValue` instead of `ArgumentError` when
  attempting to initialize with an invalid value. `ValueSemantics::InvalidValue`
  is a subclass of `ArgumentError`, so this change should be backward
  compatible.

## [3.3.0] - 2020-07-17
### Added
- Added support for pattern matching in Ruby 2.7

## [3.2.1] - 2020-07-11
### Fixed
- Fix warnings new to Ruby 2.7 about keyword arguments

## [3.2.0] - 2019-09-30
### Added
- `ValueSemantics::Struct`, a convenience for creating a new class and mixing
  in ValueSemantics in a single step.

## [3.1.0] - 2019-06-30
### Added
- Built-in PP support for value classes

## [3.0.0] - 2019-01-27

First public release
