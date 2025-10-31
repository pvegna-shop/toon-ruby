#!/usr/bin/env ruby
# frozen_string_literal: true

# This is the EXACT example from the task description

require_relative 'lib/toon'

puts "=" * 70
puts "Task Example: Roundtrip Encode/Decode with All Three Operations"
puts "=" * 70

# The exact data from the task
data = {
  "items" => [
    { "one" => { "two" => [1, 2] } },
    { "one" => { "two" => [3, 4], "three" => { "four" => 5 } } }
  ]
}

puts "\nOriginal data:"
puts data.inspect

puts "\n" + "-" * 70
puts "Encoding with normalize_on, flatten_on, and stringify_on..."
puts "-" * 70

encoded = Toon.encode(data,
  normalize_on: "items",
  flatten_on: "items",
  stringify_on: "items"
)

puts "\nEncoded TOON format:"
puts encoded

puts "\n" + "-" * 70
puts "Decoding with destringify_on, unflatten_on, and denormalize_on..."
puts "-" * 70

decoded = Toon.decode(encoded,
  destringify_on: "items",
  unflatten_on: "items",
  denormalize_on: "items"
)

puts "\nDecoded data:"
puts decoded.inspect

puts "\n" + "=" * 70
puts "RESULT"
puts "=" * 70

if decoded == data
  puts "✓ SUCCESS! Roundtrip completed successfully."
  puts "  decoded == data  # => true"
  exit 0
else
  puts "✗ FAILED! Decoded data does not match original."
  puts "\nExpected:"
  puts data.inspect
  puts "\nGot:"
  puts decoded.inspect
  exit 1
end
