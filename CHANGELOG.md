# Changelog for v1.x

## v1.0.4 (2022-07-05)

### Enhancements

  * Typespecs fixed for some aggregate return types (#6)
  * Fixed incorrect spec, add dialyxir to CI (#7)

## v1.0.3 (2022-04-07)

### Enhancements

  * Moduledocs for modules that `use Endon` will now include all the docs for the functions added by Endon.

### Deprecations

  * Removed support for Elixir 1.8, moved from `Mix.Config` to `Config` usage

## v1.0.2 (2021-4-14)

### Enhancements

  * Update `create/2` and `create/2` to accept a struct (in addition to a keyword list or map) (PR #2)

## v1.0.1 (2020-10-15)

### Bug Fixes

 * `Kernel.get_in/2` was failing on any module that used Endon due to overriding `fetch/2`, this is now fixed

## v1.0.0 (2020-4-26)

### Enhancements

  * Removed custom error structs in favor of ones from `Ecto.Repo`
  * Updated documentation to clarify purpose / function of library more clearly

### Bug Fixes

  * [Endon.get_or_create_by] is now appropriately wrapped in a transaction to prevent race conditions

### Deprecations

  * [Endon.first] and [Endon.last] both have new function signatures.
