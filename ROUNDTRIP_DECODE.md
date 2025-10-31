# Roundtrip Decode Operations

This document describes the three new inverse operations added to `Toon.decode` that enable proper roundtrip encoding/decoding.

## Overview

The TOON library now supports three new decode options that perform the inverse of the encode transformations:

- **`destringify_on`** - Inverse of `stringify_on`
- **`unflatten_on`** - Inverse of `flatten_on`
- **`denormalize_on`** - Inverse of `normalize_on`

These options allow you to encode data with transformations and then decode it back to the original form:

```ruby
data = {
  "items" => [
    { "one" => { "two" => [1, 2] } },
    { "one" => { "two" => [3, 4], "three" => { "four" => 5 } } }
  ]
}

# Encode with transformations
encoded = Toon.encode(data,
  normalize_on: "items",
  flatten_on: "items",
  stringify_on: "items"
)

# Decode with inverse operations
decoded = Toon.decode(encoded,
  destringify_on: "items",
  unflatten_on: "items",
  denormalize_on: "items"
)

decoded == data  # => true
```

## Operations

### 1. `destringify_on` - Convert Stringified Values Back

**What it does:**
- Converts stringified arrays and hashes back to their original Ruby objects
- Only affects strings that look like arrays `[...]` or hashes `{...}`
- Primitives (numbers, booleans, nil, regular strings) remain unchanged

**Example:**
```ruby
input = {
  "items" => [
    { "id" => 1, "data" => "[1, 2, 3]", "meta" => '{"key"=>"value"}' }
  ]
}

decoded = Toon.decode(Toon.encode(input), destringify_on: "items")

# Result:
{
  "items" => [
    { "id" => 1, "data" => [1, 2, 3], "meta" => { "key" => "value" } }
  ]
}
```

**Roundtrip usage:**
```ruby
data = { "items" => [{ "id" => 1, "tags" => ["ruby", "python"] }] }

encoded = Toon.encode(data, stringify_on: "items")
decoded = Toon.decode(encoded, destringify_on: "items")

decoded == data  # => true
```

### 2. `unflatten_on` - Restore Nested Hash Structures

**What it does:**
- Converts flattened keys with "/" separators back to nested hashes
- Example: `"one/two/three"` → `{"one" => {"two" => {"three" => value}}}`
- Automatically merges overlapping paths

**Example:**
```ruby
input = {
  "items" => [
    { "user/name" => "Ada", "user/id" => 1 }
  ]
}

decoded = Toon.decode(Toon.encode(input), unflatten_on: "items")

# Result:
{
  "items" => [
    { "user" => { "name" => "Ada", "id" => 1 } }
  ]
}
```

**Roundtrip usage:**
```ruby
data = {
  "items" => [
    { "one" => { "two" => 2, "three" => { "four" => 5 } } }
  ]
}

encoded = Toon.encode(data, flatten_on: "items")
decoded = Toon.decode(encoded, unflatten_on: "items")

decoded == data  # => true
```

### 3. `denormalize_on` - Remove Nil Values

**What it does:**
- Removes keys with `nil` values from hashes
- Only removes `nil`, not other falsy values like `false` or `0`
- Recursively processes nested hashes

**Example:**
```ruby
input = {
  "items" => [
    { "id" => 1, "name" => nil },
    { "id" => 2, "name" => "Ada" }
  ]
}

decoded = Toon.decode(Toon.encode(input), denormalize_on: "items")

# Result:
{
  "items" => [
    { "id" => 1 },
    { "id" => 2, "name" => "Ada" }
  ]
}
```

**Important:** `false` and `0` values are preserved:
```ruby
input = { "items" => [{ "bool" => false, "num" => 0, "nil" => nil }] }

decoded = Toon.decode(Toon.encode(input, normalize_on: "items"), denormalize_on: "items")

# Result: { "items" => [{ "bool" => false, "num" => 0 }] }
```

**Roundtrip usage:**
```ruby
data = {
  "items" => [
    { "id" => 1 },
    { "id" => 2, "name" => "Ada" }
  ]
}

encoded = Toon.encode(data, normalize_on: "items")
decoded = Toon.decode(encoded, denormalize_on: "items")

decoded == data  # => true
```

## Operation Order

The operations are applied in **reverse order** of encoding:

**Encoding order:** normalize → flatten → stringify → encode
**Decoding order:** decode → destringify → unflatten → denormalize

```ruby
# Encoding
data = { "items" => [...] }
encoded = Toon.encode(data,
  normalize_on: "items",    # 1st
  flatten_on: "items",      # 2nd
  stringify_on: "items"     # 3rd
)

# Decoding (reverse order)
decoded = Toon.decode(encoded,
  destringify_on: "items",  # 1st (inverse of 3rd)
  unflatten_on: "items",    # 2nd (inverse of 2nd)
  denormalize_on: "items"   # 3rd (inverse of 1st)
)
```

## Usage Patterns

### Using All Three Operations

The most common pattern is to use all three operations together:

```ruby
data = {
  "items" => [
    { "user" => { "name" => "Ada", "tags" => ["ruby"] } },
    { "user" => { "name" => "Bob", "tags" => ["python"], "active" => true } }
  ]
}

encoded = Toon.encode(data,
  normalize_on: "items",
  flatten_on: "items",
  stringify_on: "items"
)

decoded = Toon.decode(encoded,
  destringify_on: "items",
  unflatten_on: "items",
  denormalize_on: "items"
)

decoded == data  # => true
```

### Using Individual Operations

You can also use operations individually:

```ruby
# Just stringify/destringify
data = { "items" => [{ "id" => 1, "data" => [1, 2, 3] }] }
encoded = Toon.encode(data, stringify_on: "items")
decoded = Toon.decode(encoded, destringify_on: "items")

# Just flatten/unflatten
data = { "items" => [{ "user" => { "name" => "Ada" } }] }
encoded = Toon.encode(data, flatten_on: "items")
decoded = Toon.decode(encoded, unflatten_on: "items")

# Just normalize/denormalize
data = { "items" => [{ "id" => 1 }, { "id" => 2, "name" => "Ada" }] }
encoded = Toon.encode(data, normalize_on: "items")
decoded = Toon.decode(encoded, denormalize_on: "items")
```

### Combining Two Operations

You can combine operations as needed:

```ruby
# Normalize + Flatten
data = {
  "items" => [
    { "one" => { "two" => 2 } },
    { "one" => { "two" => 3, "three" => 4 } }
  ]
}

encoded = Toon.encode(data, normalize_on: "items", flatten_on: "items")
decoded = Toon.decode(encoded, unflatten_on: "items", denormalize_on: "items")
```

## Known Limitations

### 1. Explicit Nil Values

`denormalize_on` removes **all** nil values, including ones that were in the original data:

```ruby
# Original data has explicit nil
data = { "items" => [{ "id" => 1, "value" => nil }] }

# After roundtrip, nil is removed
encoded = Toon.encode(data, normalize_on: "items")
decoded = Toon.decode(encoded, denormalize_on: "items")

decoded  # => { "items" => [{ "id" => 1 }] }
```

This is an inherent limitation - we cannot distinguish between nil values added by normalization and explicit nil values in the original data.

### 2. Empty Hashes

Empty hashes `{}` are removed during denormalization if all their nested values were nil:

```ruby
data = { "items" => [{ "outer" => { "inner" => nil } }] }

encoded = Toon.encode(data, normalize_on: "items")
decoded = Toon.decode(encoded, denormalize_on: "items")

decoded  # => { "items" => [{}] }
```

### 3. Flattening with Array Values

When using `flatten_on` with nested structures that contain arrays, the arrays are preserved at the leaf level:

```ruby
data = {
  "items" => [
    { "one" => { "two" => [1, 2] } }
  ]
}

# After flattening: { "items" => [{ "one/two" => [1, 2] }] }
```

When arrays are values, you typically want to combine `flatten_on` with `stringify_on` for best results.

### 4. Keys with "/" Characters

If your original data has keys that contain "/" characters (not from flattening), they will be incorrectly unflattened:

```ruby
# Don't use unflatten_on if your keys naturally contain "/"
data = { "items" => [{ "path/to/file" => "value" }] }

# This will incorrectly create nested structure
decoded = Toon.decode(Toon.encode(data), unflatten_on: "items")
# => { "items" => [{ "path" => { "to" => { "file" => "value" } } }] }
```

## Implementation Files

The three inverse operations are implemented in separate modules:

- **`lib/toon/destringifier.rb`** - Implements `destringify_on`
- **`lib/toon/unflattener.rb`** - Implements `unflatten_on`
- **`lib/toon/denormalizer.rb`** - Implements `denormalize_on`

These modules are integrated into the main `Toon.decode` method in `lib/toon.rb`.

## Testing

Comprehensive tests are available in:
- `spec/roundtrip_decode_spec.rb` - RSpec test suite
- `test_roundtrip.rb` - Basic roundtrip tests
- `test_roundtrip_working.rb` - Comprehensive working tests

Run the tests:
```bash
ruby test_roundtrip_working.rb
```

All tests pass successfully, demonstrating proper roundtrip functionality.
