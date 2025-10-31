#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/toon'

puts "=" * 80
puts "FLATTEN_ON FEATURE DEMONSTRATION"
puts "=" * 80
puts

# Example 1: Basic flattening
puts "Example 1: Simple nested hash"
puts "-" * 40
input1 = { 'items' => [{ 'one' => { 'two' => 2 } }] }
puts "Input:"
puts input1.inspect
puts "\nOutput with flatten_on:"
puts Toon.encode(input1, flatten_on: 'items')
puts

# Example 2: Multiple levels of nesting
puts "Example 2: Multiple levels of nesting"
puts "-" * 40
input2 = { 'items' => [{ 'a' => { 'b' => { 'c' => 3 } } }] }
puts "Input:"
puts input2.inspect
puts "\nOutput with flatten_on:"
puts Toon.encode(input2, flatten_on: 'items')
puts

# Example 3: Mixed - hash and non-hash values
puts "Example 3: Mixed hash and non-hash values"
puts "-" * 40
input3 = { 'items' => [{ 'one' => 1, 'two' => { 'three' => 3 } }] }
puts "Input:"
puts input3.inspect
puts "\nOutput with flatten_on:"
puts Toon.encode(input3, flatten_on: 'items')
puts

# Example 4: Arrays should NOT be flattened
puts "Example 4: Arrays are NOT flattened (only hashes)"
puts "-" * 40
input4 = { 'items' => [{ 'one' => [1, 2], 'two' => { 'three' => 3 } }] }
puts "Input:"
puts input4.inspect
puts "\nOutput with flatten_on:"
puts Toon.encode(input4, flatten_on: 'items')
puts

# Example 5: Complex nested structure
puts "Example 5: Complex nested structure"
puts "-" * 40
input5 = {
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
puts "Input:"
puts input5.inspect
puts "\nOutput with flatten_on:"
puts Toon.encode(input5, flatten_on: 'items')
puts

# Example 6: With normalize_on
puts "Example 6: Integration with normalize_on"
puts "-" * 40
input6 = {
  'items' => [
    { 'one' => { 'two' => 2 } },
    { 'one' => { 'two' => 2, 'three' => 3 } }
  ]
}
puts "Input:"
puts input6.inspect
puts "\nOutput with normalize_on + flatten_on:"
puts Toon.encode(input6, normalize_on: 'items', flatten_on: 'items')
puts

# Example 7: With stringify_on
puts "Example 7: Integration with stringify_on"
puts "-" * 40
input7 = {
  'items' => [{
    'one' => { 'two' => [1, 2, 3] }
  }]
}
puts "Input:"
puts input7.inspect
puts "\nOutput with flatten_on + stringify_on:"
puts Toon.encode(input7, flatten_on: 'items', stringify_on: 'items')
puts

# Example 8: All three options together
puts "Example 8: All options together (normalize + flatten + stringify)"
puts "-" * 40
input8 = {
  'items' => [
    { 'one' => { 'two' => [1, 2] } },
    { 'one' => { 'two' => [3, 4], 'three' => { 'four' => 5 } } }
  ]
}
puts "Input:"
puts input8.inspect
puts "\nOutput with normalize_on + flatten_on + stringify_on:"
result = Toon.encode(
  input8,
  normalize_on: 'items',
  flatten_on: 'items',
  stringify_on: 'items'
)
puts result
puts

puts "=" * 80
puts "EXECUTION ORDER DEMONSTRATION"
puts "=" * 80
puts

puts "The three options are applied in this order:"
puts "1. normalize_on - ensures all hashes have the same keys"
puts "2. flatten_on   - flattens nested hashes (using '/' separator)"
puts "3. stringify_on - converts non-primitives (arrays/hashes) to strings"
puts

puts "For the input above:"
puts "Step 1 (normalize): Both hashes get 'one.two' and 'one.three.four' structure"
puts "Step 2 (flatten):   Keys become 'one/two' and 'one/three/four'"
puts "Step 3 (stringify): Arrays become strings, primitives remain unchanged"
puts

# Example 9: Multiple hashes in array
puts "Example 9: Multiple hashes with different structures"
puts "-" * 40
input9 = {
  'data' => [
    { 'id' => 1, 'meta' => { 'name' => 'Alice' } },
    { 'meta' => { 'name' => 'Bob', 'age' => 30 } },
    { 'id' => 3 }
  ]
}
puts "Input:"
puts input9.inspect
puts "\nOutput with normalize_on + flatten_on:"
puts Toon.encode(input9, normalize_on: 'data', flatten_on: 'data')
puts

# Example 10: With all formatting options
puts "Example 10: With all options (delimiter, length_marker, indent)"
puts "-" * 40
input10 = {
  'items' => [
    { 'a' => { 'b' => 1 } },
    { 'a' => { 'b' => 2, 'c' => [3, 4] } }
  ]
}
puts "Input:"
puts input10.inspect
puts "\nOutput with all options:"
result = Toon.encode(
  input10,
  normalize_on: 'items',
  flatten_on: 'items',
  stringify_on: 'items',
  delimiter: '|',
  length_marker: '#',
  indent: 4
)
puts result
puts

puts "=" * 80
puts "END OF DEMONSTRATION"
puts "=" * 80
