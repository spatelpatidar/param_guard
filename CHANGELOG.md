# Changelog

## [0.1.0] — Initial Release

### Added
- `validate_params` DSL via `include ParamGuard` mixin
- `required(:key)` and `optional(:key)` field declarations
- Chainable `.type()` with support for `:string`, `:integer`, `:float`, `:date`, `:boolean`
- Chainable `.range(min..max)` validation
- Chainable `.inclusion([list])` validation
- `ParamGuard::ValidationError` with structured `#errors` hash
- Aggregate error collection — all failures reported in a single raise
- `ActionController::Parameters` compatibility via `#to_unsafe_h`
- Zero runtime dependencies
