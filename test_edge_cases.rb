#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'lib/toon'

puts "Testing Edge Cases for Toon.decode inverse operations"
puts "=" * 60

# Test 1: Empty arrays
puts "\nTest 1: Empty arrays"
puts "-" * 60
data1 = { "items" => [] }
puts "Original: #{data1.inspect}"

encoded1 = Toon.encode(data1, normalize_on: "items", flatten_on: "items", stringify_on: "items")
decoded1 = Toon.decode(encoded1, destringify_on: "items", unflatten_on: "items", denormalize_on: "items")

puts "Roundtrip successful? #{decoded1 == data1}"

# Test 2: Empty hashes and arrays in data
puts "\nTest 2: Empty hashes and arrays"
puts "-" * 60
data2 = { "items" => [{ "id" => 1, "data" => [] }, { "id" => 2, "data" => [], "meta" => {} }] }
puts "Original: #{data2.inspect}"

encoded2 = Toon.encode(data2, normalize_on: "items", flatten_on: "items", stringify_on: "items")
decoded2 = Toon.decode(encoded2, destringify_on: "items", unflatten_on: "items", denormalize_on: "items")

puts "Roundtrip successful? #{decoded2 == data2}"

# Test 3: Strings that look like arrays but shouldn't be parsed
puts "\nTest 3: Strings that look like arrays"
puts "-" * 60
data3 = { "items" => [{ "text" => "[not an array" }] }
puts "Original: #{data3.inspect}"

encoded3 = Toon.encode(data3)
decoded3 = Toon.decode(encoded3, destringify_on: "items")

puts "Roundtrip successful? #{decoded3 == data3}"

# Test 4: Key that doesn't exist in data
puts "\nTest 4: Non-existent key"
puts "-" * 60
data4 = { "other" => [{ "id" => 1 }] }
puts "Original: #{data4.inspect}"

encoded4 = Toon.encode(data4)
decoded4 = Toon.decode(encoded4, destringify_on: "items", unflatten_on: "items", denormalize_on: "items")

puts "Roundtrip successful? #{decoded4 == data4}"

# Test 5: Deeply nested arrays
puts "\nTest 5: Deeply nested arrays"
puts "-" * 60
data5 = { "items" => [{ "matrix" => [[1, 2], [3, 4]] }] }
puts "Original: #{data5.inspect}"

encoded5 = Toon.encode(data5, stringify_on: "items")
decoded5 = Toon.decode(encoded5, destringify_on: "items")

puts "Roundtrip successful? #{decoded5 == data5}"

# Test 6: Deeply nested paths
puts "\nTest 6: Deeply nested paths"
puts "-" * 60
data6 = { "items" => [{ "a" => { "b" => { "c" => { "d" => 5 } } } }] }
puts "Original: #{data6.inspect}"

encoded6 = Toon.encode(data6, flatten_on: "items")
decoded6 = Toon.decode(encoded6, unflatten_on: "items")

puts "Roundtrip successful? #{decoded6 == data6}"

# Test 7: Mixed types with false and 0
puts "\nTest 7: False and 0 values (should not be removed)"
puts "-" * 60
data7 = { "items" => [{ "bool" => false, "num" => 0, "nil" => nil }] }
puts "Original: #{data7.inspect}"

encoded7 = Toon.encode(data7, normalize_on: "items")
decoded7 = Toon.decode(encoded7, denormalize_on: "items")

expected7 = { "items" => [{ "bool" => false, "num" => 0 }] }
puts "Expected: #{expected7.inspect}"
puts "Decoded:  #{decoded7.inspect}"
puts "Roundtrip successful? #{decoded7 == expected7}"

# Test 8: Combining two operations (normalize + flatten)
puts "\nTest 8: Normalize + Flatten (without stringify)"
puts "-" * 60
data8 = { "items" => [{ "one" => { "two" => 2 } }, { "one" => { "two" => 3, "three" => 4 } }] }
puts "Original: #{data8.inspect}"

encoded8 = Toon.encode(data8, normalize_on: "items", flatten_on: "items")
decoded8 = Toon.decode(encoded8, unflatten_on: "items", denormalize_on: "items")

puts "Roundtrip successful? #{decoded8 == data8}"

# Test 9: Hash values that are arrays (should be stringified)
puts "\nTest 9: Hash with array values"
puts "-" * 60
data9 = { "items" => [{ "tags" => ["a", "b", "c"] }, { "tags" => ["x", "y"] }] }
puts "Original: #{data9.inspect}"

encoded9 = Toon.encode(data9, stringify_on: "items")
decoded9 = Toon.decode(encoded9, destringify_on: "items")

puts "Roundtrip successful? #{decoded9 == data9}"

# Test 10: Hash with nested hash that has nil values
puts "\nTest 10: Nested hash with nil values"
puts "-" * 60
data10 = { "items" => [{ "outer" => { "inner" => nil, "value" => 1 } }] }
puts "Original: #{data10.inspect}"

encoded10 = Toon.encode(data10, normalize_on: "items")
decoded10 = Toon.decode(encoded10, denormalize_on: "items")

expected10 = { "items" => [{ "outer" => { "value" => 1 } }] }
puts "Expected: #{expected10.inspect}"
puts "Decoded:  #{decoded10.inspect}"
puts "Roundtrip successful? #{decoded10 == expected10}"

# Summary
puts "\n" + "=" * 60
puts "SUMMARY"
puts "=" * 60

results = [
  ["Empty arrays", decoded1 == data1],
  ["Empty hashes and arrays", decoded2 == data2],
  ["Strings that look like arrays", decoded3 == data3],
  ["Non-existent key", decoded4 == data4],
  ["Deeply nested arrays", decoded5 == data5],
  ["Deeply nested paths", decoded6 == data6],
  ["False and 0 values", decoded7 == expected7],
  ["Normalize + Flatten", decoded8 == data8],
  ["Hash with array values", decoded9 == data9],
  ["Nested hash with nil values", decoded10 == expected10]
]

results.each do |test_name, success|
  status = success ? "PASS" : "FAIL"
  puts "#{test_name}: #{status}"
end

all_passed = results.all? { |_, success| success }
puts "\nAll edge case tests passed? #{all_passed}"

exit(all_passed ? 0 : 1)
