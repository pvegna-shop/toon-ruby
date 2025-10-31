#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'lib/toon'

puts "Testing Toon.decode with inverse operations"
puts "=" * 60

# Test 1: The main example from the task description
puts "\nTest 1: Main example from task description"
puts "-" * 60
data = {
  "items" => [
    { "one" => { "two" => [1, 2] } },
    { "one" => { "two" => [3, 4], "three" => { "four" => 5 } } }
  ]
}

puts "Original data:"
p data

encoded = Toon.encode(data, normalize_on: "items", flatten_on: "items", stringify_on: "items")
puts "\nEncoded TOON:"
puts encoded

decoded = Toon.decode(encoded, destringify_on: "items", unflatten_on: "items", denormalize_on: "items")
puts "\nDecoded data:"
p decoded

puts "\nRoundtrip successful? #{decoded == data}"

# Test 2: Test destringify_on alone
puts "\n\nTest 2: destringify_on alone"
puts "-" * 60
data2 = { "items" => [{ "id" => 1, "data" => [1, 2, 3] }, { "id" => 2, "data" => [4, 5] }] }
puts "Original data:"
p data2

encoded2 = Toon.encode(data2, stringify_on: "items")
puts "\nEncoded TOON:"
puts encoded2

decoded2 = Toon.decode(encoded2, destringify_on: "items")
puts "\nDecoded data:"
p decoded2

puts "\nRoundtrip successful? #{decoded2 == data2}"

# Test 3: Test unflatten_on alone
puts "\n\nTest 3: unflatten_on alone"
puts "-" * 60
data3 = { "items" => [{ "one" => { "two" => 2 } }, { "one" => { "two" => 3, "three" => 4 } }] }
puts "Original data:"
p data3

encoded3 = Toon.encode(data3, flatten_on: "items")
puts "\nEncoded TOON:"
puts encoded3

decoded3 = Toon.decode(encoded3, unflatten_on: "items")
puts "\nDecoded data:"
p decoded3

puts "\nRoundtrip successful? #{decoded3 == data3}"

# Test 4: Test denormalize_on alone
puts "\n\nTest 4: denormalize_on alone"
puts "-" * 60
data4 = { "items" => [{ "id" => 1 }, { "id" => 2, "name" => "Ada" }] }
puts "Original data:"
p data4

encoded4 = Toon.encode(data4, normalize_on: "items")
puts "\nEncoded TOON:"
puts encoded4

decoded4 = Toon.decode(encoded4, denormalize_on: "items")
puts "\nDecoded data:"
p decoded4

puts "\nRoundtrip successful? #{decoded4 == data4}"

# Test 5: Complex nested data
puts "\n\nTest 5: Complex nested data"
puts "-" * 60
data5 = {
  "items" => [
    { "user" => { "name" => "Ada", "tags" => ["ruby", "programming"] } },
    { "user" => { "name" => "Bob", "tags" => ["python"], "active" => true } }
  ]
}
puts "Original data:"
p data5

encoded5 = Toon.encode(data5, normalize_on: "items", flatten_on: "items", stringify_on: "items")
puts "\nEncoded TOON:"
puts encoded5

decoded5 = Toon.decode(encoded5, destringify_on: "items", unflatten_on: "items", denormalize_on: "items")
puts "\nDecoded data:"
p decoded5

puts "\nRoundtrip successful? #{decoded5 == data5}"

# Summary
puts "\n" + "=" * 60
puts "SUMMARY"
puts "=" * 60
results = [
  ["Main example", decoded == data],
  ["destringify_on alone", decoded2 == data2],
  ["unflatten_on alone", decoded3 == data3],
  ["denormalize_on alone", decoded4 == data4],
  ["Complex nested data", decoded5 == data5]
]

results.each do |test_name, success|
  status = success ? "PASS" : "FAIL"
  puts "#{test_name}: #{status}"
end

all_passed = results.all? { |_, success| success }
puts "\nAll tests passed? #{all_passed}"

exit(all_passed ? 0 : 1)
