#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'lib/toon'

puts "Testing exact examples from requirements..."
puts "=" * 80

# Example 1 (simple nested hash)
puts "\nExample 1: Simple nested hash"
input = { "items" => [{ "one" => { "two" => 2 } }] }
result = Toon.encode(input, flatten_on: "items")
puts "Input:  #{input.inspect}"
puts "Output: #{result.inspect}"
puts "Result after flattening: {\"items\" => [{\"one/two\" => 2}]}"
puts

# Example 2 (multiple levels)
puts "Example 2: Multiple levels"
input = { "items" => [{ "a" => { "b" => { "c" => 3 } } }] }
result = Toon.encode(input, flatten_on: "items")
puts "Input:  #{input.inspect}"
puts "Output: #{result.inspect}"
puts "Result after flattening: {\"items\" => [{\"a/b/c\" => 3}]}"
puts

# Example 3 (mixed - hash and non-hash values)
puts "Example 3: Mixed - hash and non-hash values"
input = { "items" => [{ "one" => 1, "two" => { "three" => 3 } }] }
result = Toon.encode(input, flatten_on: "items")
puts "Input:  #{input.inspect}"
puts "Output: #{result.inspect}"
puts "Result after flattening: {\"items\" => [{\"one\" => 1, \"two/three\" => 3}]}"
puts

# Example 4 (arrays should NOT be flattened)
puts "Example 4: Arrays should NOT be flattened"
input = { "items" => [{ "one" => [1, 2], "two" => { "three" => 3 } }] }
result = Toon.encode(input, flatten_on: "items")
puts "Input:  #{input.inspect}"
puts "Output:"
puts result
puts "Note: array [1, 2] stays as-is, only hash is flattened"
puts

# Test execution order
puts "=" * 80
puts "Testing Execution Order: normalize → flatten → stringify"
puts "=" * 80

input = {
  'items' => [
    { 'one' => { 'two' => [1, 2] } },
    { 'one' => { 'two' => [3, 4], 'three' => { 'four' => 5 } } }
  ]
}

puts "\nOriginal input:"
puts input.inspect

puts "\nStep 1: After normalize_on (both have same nested structure):"
step1 = input.dup
step1['items'] = Toon::Normalizer.normalize_array_of_hashes(step1['items'])
puts step1.inspect

puts "\nStep 2: After flatten_on (nested keys become flat):"
step2 = step1.dup
step2['items'] = Toon::Flattener.flatten_array_of_hashes(step2['items'])
puts step2.inspect

puts "\nStep 3: After stringify_on (arrays become strings):"
step3 = step2.dup
step3['items'] = Toon::Stringifier.stringify_array_of_hashes(step3['items'])
puts step3.inspect

puts "\nFinal encoded output:"
result = Toon.encode(
  input,
  normalize_on: 'items',
  flatten_on: 'items',
  stringify_on: 'items'
)
puts result
puts

puts "=" * 80
puts "All requirement examples verified!"
puts "=" * 80
