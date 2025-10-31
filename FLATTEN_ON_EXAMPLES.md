# flatten_on Feature Examples

## Basic Usage

### Example 1: Simple Nested Hash
```ruby
input = { 'items' => [{ 'one' => { 'two' => 2 } }] }
Toon.encode(input, flatten_on: 'items')
```
**Output:**
```
items[1]{"one/two"}:
  2
```

### Example 2: Multiple Levels of Nesting
```ruby
input = { 'items' => [{ 'a' => { 'b' => { 'c' => 3 } } }] }
Toon.encode(input, flatten_on: 'items')
```
**Output:**
```
items[1]{"a/b/c"}:
  3
```

### Example 3: Mixed Hash and Non-Hash Values
```ruby
input = { 'items' => [{ 'one' => 1, 'two' => { 'three' => 3 } }] }
Toon.encode(input, flatten_on: 'items')
```
**Output:**
```
items[1]{one,"two/three"}:
  1,3
```

### Example 4: Arrays Are NOT Flattened
```ruby
input = { 'items' => [{ 'one' => [1, 2], 'two' => { 'three' => 3 } }] }
Toon.encode(input, flatten_on: 'items')
```
**Output:**
```
items[1]:
  - one[2]: 1,2
    "two/three": 3
```
Note: The array `[1, 2]` stays as-is; only the hash is flattened.

## Complex Example

### Example 5: Complex Nested Structure
```ruby
input = {
  'items' => [{
    'id' => 1,
    'meta' => {
      'author' => 'Alice',
      'tags' => {
        'primary' => 'tech',
        'secondary' => 'ai'
      }
    }
  }]
}
Toon.encode(input, flatten_on: 'items')
```
**Output:**
```
items[1]{id,"meta/author","meta/tags/primary","meta/tags/secondary"}:
  1,Alice,tech,ai
```

## Integration with normalize_on

### Example 6: Flattening After Normalization
```ruby
input = {
  'items' => [
    { 'one' => { 'two' => 2 } },
    { 'one' => { 'two' => 2, 'three' => 3 } }
  ]
}
Toon.encode(input, normalize_on: 'items', flatten_on: 'items')
```

**Step-by-step:**
1. **After normalize_on:** Both hashes have same nested structure
   ```ruby
   [
     { 'one' => { 'two' => 2, 'three' => nil } },
     { 'one' => { 'two' => 2, 'three' => 3 } }
   ]
   ```

2. **After flatten_on:** Nested keys become flat
   ```ruby
   [
     { 'one/two' => 2, 'one/three' => nil },
     { 'one/two' => 2, 'one/three' => 3 }
   ]
   ```

**Output:**
```
items[2]{"one/two","one/three"}:
  2,null
  2,3
```

## Integration with stringify_on

### Example 7: Flattening Before Stringification
```ruby
input = { 'items' => [{ 'one' => { 'two' => [1, 2, 3] } }] }
Toon.encode(input, flatten_on: 'items', stringify_on: 'items')
```

**Step-by-step:**
1. **After flatten_on:** Nested hash is flattened
   ```ruby
   [{ 'one/two' => [1, 2, 3] }]
   ```

2. **After stringify_on:** Arrays become strings
   ```ruby
   [{ 'one/two' => "[1, 2, 3]" }]
   ```

**Output:**
```
items[1]{"one/two"}:
  "[1, 2, 3]"
```

## All Three Options Together

### Example 8: Complete Pipeline
```ruby
input = {
  'items' => [
    { 'one' => { 'two' => [1, 2] } },
    { 'one' => { 'two' => [3, 4], 'three' => { 'four' => 5 } } }
  ]
}
Toon.encode(
  input,
  normalize_on: 'items',
  flatten_on: 'items',
  stringify_on: 'items'
)
```

**Execution Order: normalize → flatten → stringify**

1. **After normalize_on:** Both hashes have same nested structure
   ```ruby
   [
     { 'one' => { 'two' => [1, 2], 'three' => { 'four' => nil } } },
     { 'one' => { 'two' => [3, 4], 'three' => { 'four' => 5 } } }
   ]
   ```

2. **After flatten_on:** Nested keys become flat
   ```ruby
   [
     { 'one/two' => [1, 2], 'one/three/four' => nil },
     { 'one/two' => [3, 4], 'one/three/four' => 5 }
   ]
   ```

3. **After stringify_on:** Arrays become strings, primitives unchanged
   ```ruby
   [
     { 'one/two' => "[1, 2]", 'one/three/four' => nil },
     { 'one/two' => "[3, 4]", 'one/three/four' => 5 }
   ]
   ```

**Output:**
```
items[2]{"one/two","one/three/four"}:
  "[1, 2]",null
  "[3, 4]",5
```

## With All Options

### Example 9: All Options Combined
```ruby
input = {
  'items' => [
    { 'a' => { 'b' => 1 } },
    { 'a' => { 'b' => 2, 'c' => [3, 4] } }
  ]
}
Toon.encode(
  input,
  normalize_on: 'items',
  flatten_on: 'items',
  stringify_on: 'items',
  delimiter: '|',
  length_marker: '#',
  indent: 4
)
```

**Output:**
```
items[#2|]{"a/b"|"a/c"}:
    1|null
    2|"[3, 4]"
```

## Real-World Use Case

### Example 10: Flattening Complex Metadata
```ruby
input = {
  'data' => [
    { 'id' => 1, 'meta' => { 'tags' => ['a', 'b'] } },
    { 'meta' => { 'tags' => ['c'], 'priority' => 2 } }
  ]
}
Toon.encode(
  input,
  normalize_on: 'data',
  flatten_on: 'data',
  stringify_on: 'data'
)
```

**Output:**
```
data[2]{id,"meta/tags","meta/priority"}:
  1,"[\"a\", \"b\"]",null
  null,"[\"c\"]",2
```

This is useful when you have nested metadata structures that you want to:
1. Normalize (ensure all records have same fields)
2. Flatten (make nested fields into flat keys)
3. Stringify (convert complex values to strings for tabular format)

## Key Points

- **Separator:** Uses "/" to join nested keys
- **Recursion:** Flattens to any depth
- **Arrays:** NOT flattened, only hashes
- **Order:** Always runs in sequence: normalize → flatten → stringify
- **Compatibility:** Works with all other options (delimiter, length_marker, indent)
- **Safety:** When `flatten_on` is `nil` or key doesn't exist, no flattening occurs
