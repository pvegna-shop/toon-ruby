#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'lib/toon'

puts "=" * 80
puts "Demonstration of stringify_on Feature"
puts "=" * 80
puts

# Example 1: Basic usage as specified in requirements
puts "Example 1: Basic usage (from requirements)"
puts "-" * 80
input = { "columns" => [{ "one" => 1, "two" => [2], "three" => { "three" => 3 } }] }
puts "Input:"
puts input.inspect
puts
puts "Output with stringify_on: 'columns':"
puts Toon.encode(input, stringify_on: "columns")
puts
puts "Expected behavior:"
puts "- Primitives (1) stay as-is"
puts "- Arrays ([2]) become strings: \"[2]\""
puts "- Hashes ({\"three\" => 3}) become strings: \"{\\\"three\\\"=>3}\""
puts

# Example 2: Showing primitive preservation
puts "Example 2: Primitive preservation"
puts "-" * 80
input = { "data" => [{ "string" => "text", "number" => 42, "bool" => true, "null" => nil, "array" => [1, 2, 3] }] }
puts "Input:"
puts input.inspect
puts
puts "Output with stringify_on: 'data':"
puts Toon.encode(input, stringify_on: "data")
puts
puts "Notice: strings, numbers, booleans, and nil remain unchanged"
puts "        only the array [1, 2, 3] is converted to a string"
puts

# Example 3: normalize_on and stringify_on together
puts "Example 3: Using normalize_on and stringify_on together"
puts "-" * 80
input = {
  "records" => [
    { "id" => 1, "name" => "Alice" },
    { "id" => 2, "name" => "Bob", "metadata" => { "role" => "admin" } }
  ]
}
puts "Input (records have different keys):"
puts input.inspect
puts
puts "Without any options:"
puts Toon.encode(input)
puts
puts "With normalize_on only:"
puts Toon.encode(input, normalize_on: "records")
puts
puts "With both normalize_on and stringify_on:"
puts Toon.encode(input, normalize_on: "records", stringify_on: "records")
puts
puts "Explanation:"
puts "1. normalize_on adds missing keys (Alice gets metadata: nil)"
puts "2. stringify_on converts the hash to a string for Bob"
puts "3. Execution order: normalize THEN stringify"
puts

# Example 4: Complex nested structures
puts "Example 4: Complex nested structures"
puts "-" * 80
input = {
  "items" => [
    {
      "id" => 1,
      "tags" => ["ruby", "code"],
      "config" => { "enabled" => true, "level" => 5 },
      "matrix" => [[1, 2], [3, 4]]
    },
    {
      "id" => 2,
      "tags" => ["python"],
      "config" => { "enabled" => false },
      "matrix" => [[5, 6]]
    }
  ]
}
puts "Input:"
puts input.inspect
puts
puts "With stringify_on: 'items':"
result = Toon.encode(input, stringify_on: "items")
puts result
puts
puts "All non-primitive values (arrays and hashes) are now strings!"
puts

# Example 5: Integration with other options
puts "Example 5: All options combined"
puts "-" * 80
input = {
  "data" => [
    { "a" => 1 },
    { "a" => 2, "b" => [10, 20], "c" => { "x" => "y" } }
  ]
}
puts "Input:"
puts input.inspect
puts
puts "With all options (normalize_on, stringify_on, delimiter='|', length_marker='#', indent=4):"
result = Toon.encode(
  input,
  normalize_on: "data",
  stringify_on: "data",
  delimiter: "|",
  length_marker: "#",
  indent: 4
)
puts result
puts

puts "=" * 80
puts "Feature Summary"
puts "=" * 80
puts "The stringify_on option:"
puts "✓ Converts arrays and hashes to strings within array of hashes"
puts "✓ Preserves primitives (strings, numbers, booleans, nil)"
puts "✓ Works after normalize_on (correct execution order)"
puts "✓ Integrates with all other options (delimiter, length_marker, indent)"
puts "✓ Uses Ruby's .inspect for string representation"
puts "✓ Handles edge cases (empty arrays/hashes, nested structures)"
