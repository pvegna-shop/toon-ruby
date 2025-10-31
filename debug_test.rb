#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'lib/toon'

# Test 2: Empty hashes and arrays in data
puts "Test 2: Empty hashes and arrays"
puts "-" * 60
data2 = { "items" => [{ "id" => 1, "data" => [] }, { "id" => 2, "data" => [], "meta" => {} }] }
puts "Original: #{data2.inspect}"

encoded2 = Toon.encode(data2, normalize_on: "items", flatten_on: "items", stringify_on: "items")
puts "\nEncoded:"
puts encoded2

decoded2 = Toon.decode(encoded2, destringify_on: "items", unflatten_on: "items", denormalize_on: "items")
puts "\nDecoded: #{decoded2.inspect}"

puts "\nAre they equal? #{decoded2 == data2}"

# Let's check what happens step by step
puts "\n--- Step by step ---"

# Just decode without any operations
decoded_raw = Toon.decode(encoded2)
puts "\nAfter basic decode: #{decoded_raw.inspect}"

# After destringify
decoded_after_destringify = Toon.decode(encoded2, destringify_on: "items")
puts "\nAfter destringify: #{decoded_after_destringify.inspect}"

# After unflatten
decoded_after_unflatten = Toon.decode(encoded2, destringify_on: "items", unflatten_on: "items")
puts "\nAfter unflatten: #{decoded_after_unflatten.inspect}"

# After denormalize
decoded_after_denormalize = Toon.decode(encoded2, destringify_on: "items", unflatten_on: "items", denormalize_on: "items")
puts "\nAfter denormalize: #{decoded_after_denormalize.inspect}"

puts "\n\n" + "=" * 60

# Test 10: Nested hash with nil values
puts "\nTest 10: Nested hash with nil values"
puts "-" * 60
data10 = { "items" => [{ "outer" => { "inner" => nil, "value" => 1 } }] }
puts "Original: #{data10.inspect}"

encoded10 = Toon.encode(data10, normalize_on: "items")
puts "\nEncoded:"
puts encoded10

decoded10 = Toon.decode(encoded10, denormalize_on: "items")
puts "\nDecoded: #{decoded10.inspect}"

expected10 = { "items" => [{ "outer" => { "value" => 1 } }] }
puts "\nExpected: #{expected10.inspect}"
puts "Are they equal? #{decoded10 == expected10}"

# Let's check what happens step by step
puts "\n--- Step by step ---"

# Just decode without any operations
decoded10_raw = Toon.decode(encoded10)
puts "\nAfter basic decode: #{decoded10_raw.inspect}"

# After denormalize
decoded10_after = Toon.decode(encoded10, denormalize_on: "items")
puts "\nAfter denormalize: #{decoded10_after.inspect}"
