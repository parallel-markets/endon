# Changelog

## v2.0.2 (2024-07-08)

  * Add support for Elixir 1.17.x

## v2.0.1 (2023-08-11)

### Enhancements

  * Add support for the `:lock` option (#8)

## v2.0.0 (2023-08-01)

### Breaking Changes

  * All support for the `stream_where/2` function was removed in favor of https://hexdocs.pm/ecto/Ecto.Repo.html#c:stream/2

### Bug Fixes

  * Fixed a bug that would have caused issues with first/last/fetch/find when there is no primary key (or a composite primary key)

## v1.0.6 (2022-09-26)

### Enhancements

  * Minor documentation / @spec fixes (#1)

## v1.0.5 (2022-07-05)

### Enhancements

  * Updated all references to point to new repo location owned by Parallel Markets

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
