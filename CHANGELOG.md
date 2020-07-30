# Changelog

Notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Changed
- Improved exception messages for easier development experience

- Raises `ValueSemantics::InvalidValue` instead of `ArgumentError` when
  attempting to initialize with an invalid value. `ValueSemantics::InvalidValue`
  is a subclass of `ArgumentError`, so it should be backwards compatible.

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
