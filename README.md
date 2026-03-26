# ParamGuard 🛡️

A clean, chainable DSL for validating controller and service object parameters in Ruby/Rails — before they ever touch your business logic.

```ruby
validate_params(params) do
  required(:date).type(:date)
  optional(:latitude).type(:float).range(-90.0..90.0)
  optional(:status).inclusion(%w[pending confirmed cancelled])
end
```

## Features

- **`required` / `optional`** field declarations
- **Type coercion** — `:string`, `:integer`, `:float`, `:date`, `:boolean`
- **Range validation** — `.range(min..max)`
- **Inclusion validation** — `.inclusion([allowed, values])`
- **Chainable** — all rules chain fluently off the field declaration
- **Aggregate errors** — collects *all* failures before raising, never stops at the first
- **Structured errors** — `ValidationError#errors` gives a `Hash{Symbol => Array<String>}` for easy JSON responses
- **Zero dependencies** — pure Ruby, no Rails required

---

## Installation

Add to your `Gemfile`:

```ruby
gem "param_guard"
```

Or install directly:

```sh
gem install param_guard
```

---

## Usage

### 1. Include the mixin

```ruby
class BookingsController < ApplicationController
  include ParamGuard   # ← adds validate_params
end
```

Works equally well in service objects, interactors, form objects, etc.

### 2. Declare your parameters

```ruby
def create
  cleaned = validate_params(params) do
    required(:date).type(:date)
    optional(:latitude).type(:float).range(-90.0..90.0)
    optional(:longitude).type(:float).range(-180.0..180.0)
    optional(:guests).type(:integer).range(1..20)
    optional(:status).inclusion(%w[pending confirmed cancelled])
  end

  # cleaned => { date: #<Date 2024-06-15>, latitude: 45.5, guests: 3, ... }
  Reservation.create!(cleaned)
end
```

### 3. Handle errors

```ruby
rescue ParamGuard::ValidationError => e
  # Human-readable summary
  e.message
  # => "Validation failed: date is required; latitude must be in range -90.0..90.0"

  # Structured hash for JSON APIs
  render json: { errors: e.errors }, status: :unprocessable_entity
  # => { errors: { date: ["is required"], latitude: ["must be in range -90.0..90.0"] } }
```

---

## DSL Reference

### `required(key)`

The field **must** be present and non-blank. Raises `ValidationError` if missing.

### `optional(key)`

The field may be absent. If absent, all chained validators are silently skipped.

### `.type(kind)`

Coerces and validates the field's type. Supported kinds:

| Kind        | Accepts                              | Returns        |
|-------------|--------------------------------------|----------------|
| `:string`   | anything                             | `String`       |
| `:integer`  | `"42"`, `42`                         | `Integer`      |
| `:float`    | `"3.14"`, `3.14`, `"10"`            | `Float`        |
| `:date`     | `"2024-06-15"`, `Date` object        | `Date`         |
| `:boolean`  | `"true"/"false"`, `"1"/"0"`, `"yes"/"no"` | `true`/`false` |

### `.range(min..max)`

Checks that the (coerced) value falls within the given `Range`. Works with integers, floats, and any `Comparable`.

```ruby
optional(:score).type(:float).range(0.0..100.0)
```

### `.inclusion([...])`

Checks that the (coerced) value is a member of the given Array.

```ruby
optional(:role).inclusion(%w[admin editor viewer])
optional(:priority).type(:integer).inclusion([1, 2, 3])
```

---

## Service Object Example

```ruby
class CreateReservation
  include ParamGuard

  def call(raw_params)
    params = validate_params(raw_params) do
      required(:date).type(:date)
      required(:user_id).type(:integer)
      optional(:guests).type(:integer).range(1..20)
    end

    Reservation.create!(params)
  rescue ParamGuard::ValidationError => e
    Result.failure(e.errors)
  end
end
```

---

## Architecture

```
lib/
├── param_guard.rb                  # Entry point + include hook
└── param_guard/
    ├── version.rb                  # VERSION constant
    ├── validation_error.rb         # Custom exception with #errors hash
    ├── field_validator.rb          # Chainable per-field rule builder
    ├── validator.rb                # DSL context (runs the block)
    └── mixin.rb                    # validate_params method
```

---

## Running Tests

```sh
bundle install
bundle exec rspec
```

---

## License

MIT
