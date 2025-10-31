#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/toon'

puts "=== Normalize On Feature Demo ==="
puts

# Example 1: Simple case
puts "Example 1: Simple case"
puts "Input: #{{"columns" => [{"one" => 1}, {"one" => 1, "two" => 2}]}.inspect}"
input1 = {"columns" => [{"one" => 1}, {"one" => 1, "two" => 2}]}
result1 = Toon.encode(input1, normalize_on: "columns")
puts "Result with normalize_on: 'columns':"
puts result1
puts

# Show without normalization
result1_no_norm = Toon.encode(input1)
puts "Result WITHOUT normalize_on (for comparison):"
puts result1_no_norm
puts
puts "---"
puts

# Example 2: Nested case
puts "Example 2: Nested case"
input2 = {"columns" => [{"one" => 1}, {"one" => 1, "two" => {"three" => 3}}]}
puts "Input: #{input2.inspect}"
result2 = Toon.encode(input2, normalize_on: "columns")
puts "Result with normalize_on: 'columns':"
puts result2
puts

# Show without normalization
result2_no_norm = Toon.encode(input2)
puts "Result WITHOUT normalize_on (for comparison):"
puts result2_no_norm
puts
puts "---"
puts

# Example 3: Multiple missing keys
puts "Example 3: Multiple missing keys across different hashes"
input3 = {"data" => [{"a" => 1, "b" => 2}, {"a" => 3}, {"c" => 5}]}
puts "Input: #{input3.inspect}"
result3 = Toon.encode(input3, normalize_on: "data")
puts "Result with normalize_on: 'data':"
puts result3
puts

# Show without normalization
result3_no_norm = Toon.encode(input3)
puts "Result WITHOUT normalize_on (for comparison):"
puts result3_no_norm
puts
puts "---"
puts

# Example 4: Deeply nested structures
puts "Example 4: Deeply nested structures"
input4 = {
  "items" => [
    {"a" => {"b" => {"c" => 1}}},
    {"a" => {"b" => {}}},
    {"a" => {}}
  ]
}
puts "Input: #{input4.inspect}"
result4 = Toon.encode(input4, normalize_on: "items")
puts "Result with normalize_on: 'items':"
puts result4
puts

# Show without normalization
result4_no_norm = Toon.encode(input4)
puts "Result WITHOUT normalize_on (for comparison):"
puts result4_no_norm
puts
puts "---"
puts

# Example 5: Works with other options
puts "Example 5: Combining normalize_on with other options"
input5 = {"columns" => [{"one" => 1}, {"one" => 1, "two" => 2}]}
puts "Input: #{input5.inspect}"
result5 = Toon.encode(input5, normalize_on: "columns", delimiter: "|", length_marker: "#")
puts "Result with normalize_on + delimiter: '|' + length_marker: '#':"
puts result5
puts

puts "=== Demo Complete ==="
