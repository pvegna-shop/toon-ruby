#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'lib/toon'

puts "=" * 70
puts "Comprehensive Roundtrip Tests for Toon.decode"
puts "=" * 70

test_results = []

# Test 1: Main example from task description (normalize + flatten + stringify)
puts "\n[1] Main example from task description (all three operations)"
puts "-" * 70
data1 = {
  "items" => [
    { "one" => { "two" => [1, 2] } },
    { "one" => { "two" => [3, 4], "three" => { "four" => 5 } } }
  ]
}
puts "Original:"
p data1

encoded1 = Toon.encode(data1, normalize_on: "items", flatten_on: "items", stringify_on: "items")
puts "\nEncoded TOON:"
puts encoded1

decoded1 = Toon.decode(encoded1, destringify_on: "items", unflatten_on: "items", denormalize_on: "items")
puts "\nDecoded:"
p decoded1

result1 = decoded1 == data1
test_results << ["Main example (all three ops)", result1]
puts "\n=> #{result1 ? 'PASS' : 'FAIL'}"

# Test 2: destringify_on with arrays
puts "\n[2] destringify_on with arrays"
puts "-" * 70
data2 = { "items" => [{ "id" => 1, "data" => [1, 2, 3] }, { "id" => 2, "data" => [4, 5] }] }
puts "Original: #{data2.inspect}"

encoded2 = Toon.encode(data2, stringify_on: "items")
decoded2 = Toon.decode(encoded2, destringify_on: "items")

result2 = decoded2 == data2
test_results << ["destringify_on with arrays", result2]
puts "=> #{result2 ? 'PASS' : 'FAIL'}"

# Test 3: destringify_on with nested hashes
puts "\n[3] destringify_on with nested hashes"
puts "-" * 70
data3 = { "items" => [{ "id" => 1, "meta" => { "key" => "value" } }] }
puts "Original: #{data3.inspect}"

encoded3 = Toon.encode(data3, stringify_on: "items")
decoded3 = Toon.decode(encoded3, destringify_on: "items")

result3 = decoded3 == data3
test_results << ["destringify_on with hashes", result3]
puts "=> #{result3 ? 'PASS' : 'FAIL'}"

# Test 4: unflatten_on with simple nested structure (works with tabular format)
puts "\n[4] unflatten_on with simple nested paths"
puts "-" * 70
data4 = {
  "items" => [
    { "user" => { "name" => "Ada", "id" => 1 } },
    { "user" => { "name" => "Bob", "id" => 2 } }
  ]
}
puts "Original: #{data4.inspect}"

encoded4 = Toon.encode(data4, flatten_on: "items")
puts "\nEncoded:"
puts encoded4
decoded4 = Toon.decode(encoded4, unflatten_on: "items")

result4 = decoded4 == data4
test_results << ["unflatten_on simple", result4]
puts "=> #{result4 ? 'PASS' : 'FAIL'}"

# Test 5: denormalize_on removes nil values
puts "\n[5] denormalize_on removes nil values"
puts "-" * 70
data5 = { "items" => [{ "id" => 1 }, { "id" => 2, "name" => "Ada" }] }
puts "Original: #{data5.inspect}"

encoded5 = Toon.encode(data5, normalize_on: "items")
decoded5 = Toon.decode(encoded5, denormalize_on: "items")

result5 = decoded5 == data5
test_results << ["denormalize_on", result5]
puts "=> #{result5 ? 'PASS' : 'FAIL'}"

# Test 6: All three operations with primitive-only nested values
puts "\n[6] All three operations with string values"
puts "-" * 70
data6 = {
  "items" => [
    { "user" => { "name" => "Ada", "email" => "ada@example.com" } },
    { "user" => { "name" => "Bob", "email" => "bob@example.com", "active" => true } }
  ]
}
puts "Original: #{data6.inspect}"

encoded6 = Toon.encode(data6, normalize_on: "items", flatten_on: "items", stringify_on: "items")
decoded6 = Toon.decode(encoded6, destringify_on: "items", unflatten_on: "items", denormalize_on: "items")

result6 = decoded6 == data6
test_results << ["All three ops (primitives)", result6]
puts "=> #{result6 ? 'PASS' : 'FAIL'}"

# Test 7: Empty arrays
puts "\n[7] Empty arrays"
puts "-" * 70
data7 = { "items" => [] }
puts "Original: #{data7.inspect}"

encoded7 = Toon.encode(data7, normalize_on: "items", flatten_on: "items", stringify_on: "items")
decoded7 = Toon.decode(encoded7, destringify_on: "items", unflatten_on: "items", denormalize_on: "items")

result7 = decoded7 == data7
test_results << ["Empty arrays", result7]
puts "=> #{result7 ? 'PASS' : 'FAIL'}"

# Test 8: Preserve false and 0
puts "\n[8] Preserve false and 0 values"
puts "-" * 70
data8_input = { "items" => [{ "bool" => false, "num" => 0, "str" => "test", "nil" => nil }] }
data8_expected = { "items" => [{ "bool" => false, "num" => 0, "str" => "test" }] }
puts "Original: #{data8_input.inspect}"

encoded8 = Toon.encode(data8_input, normalize_on: "items")
decoded8 = Toon.decode(encoded8, denormalize_on: "items")

result8 = decoded8 == data8_expected
test_results << ["Preserve false and 0", result8]
puts "=> #{result8 ? 'PASS' : 'FAIL'}"

# Test 9: Deeply nested arrays
puts "\n[9] Deeply nested arrays"
puts "-" * 70
data9 = { "items" => [{ "matrix" => [[1, 2], [3, 4]] }] }
puts "Original: #{data9.inspect}"

encoded9 = Toon.encode(data9, stringify_on: "items")
decoded9 = Toon.decode(encoded9, destringify_on: "items")

result9 = decoded9 == data9
test_results << ["Deeply nested arrays", result9]
puts "=> #{result9 ? 'PASS' : 'FAIL'}"

# Test 10: Deeply nested hash paths
puts "\n[10] Deeply nested hash paths"
puts "-" * 70
data10 = {
  "items" => [
    { "a" => { "b" => { "c" => { "d" => 5 } } } }
  ]
}
puts "Original: #{data10.inspect}"

encoded10 = Toon.encode(data10, flatten_on: "items")
puts "\nEncoded:"
puts encoded10
decoded10 = Toon.decode(encoded10, unflatten_on: "items")

result10 = decoded10 == data10
test_results << ["Deeply nested paths", result10]
puts "=> #{result10 ? 'PASS' : 'FAIL'}"

# Test 11: Combining normalize and flatten (primitives only)
puts "\n[11] Normalize + Flatten (primitives only)"
puts "-" * 70
data11 = {
  "items" => [
    { "one" => { "two" => 2 } },
    { "one" => { "two" => 3, "three" => 4 } }
  ]
}
puts "Original: #{data11.inspect}"

encoded11 = Toon.encode(data11, normalize_on: "items", flatten_on: "items")
decoded11 = Toon.decode(encoded11, unflatten_on: "items", denormalize_on: "items")

result11 = decoded11 == data11
test_results << ["Normalize + Flatten", result11]
puts "=> #{result11 ? 'PASS' : 'FAIL'}"

# Test 12: Non-existent key
puts "\n[12] Non-existent key (should pass through unchanged)"
puts "-" * 70
data12 = { "other" => [{ "id" => 1 }] }
puts "Original: #{data12.inspect}"

encoded12 = Toon.encode(data12)
decoded12 = Toon.decode(encoded12, destringify_on: "items", unflatten_on: "items", denormalize_on: "items")

result12 = decoded12 == data12
test_results << ["Non-existent key", result12]
puts "=> #{result12 ? 'PASS' : 'FAIL'}"

# Test 13: Strings that look like arrays
puts "\n[13] Strings that look like arrays (but aren't)"
puts "-" * 70
data13 = { "items" => [{ "text" => "[not an array" }] }
puts "Original: #{data13.inspect}"

encoded13 = Toon.encode(data13)
decoded13 = Toon.decode(encoded13, destringify_on: "items")

result13 = decoded13 == data13
test_results << ["Invalid array strings", result13]
puts "=> #{result13 ? 'PASS' : 'FAIL'}"

# Summary
puts "\n" + "=" * 70
puts "SUMMARY"
puts "=" * 70

test_results.each_with_index do |(test_name, success), index|
  status = success ? "\u2713 PASS" : "\u2717 FAIL"
  puts "[#{index + 1}] #{status} - #{test_name}"
end

passed = test_results.count { |_, success| success }
total = test_results.length

puts "\n#{passed}/#{total} tests passed"

all_passed = test_results.all? { |_, success| success }
exit(all_passed ? 0 : 1)
