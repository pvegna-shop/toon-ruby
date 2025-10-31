#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'lib/toon'

def test(name, actual, expected)
  if actual == expected
    puts "[PASS] #{name}"
    true
  else
    puts "[FAIL] #{name}"
    puts "  Expected: #{expected.inspect}"
    puts "  Actual:   #{actual.inspect}"
    false
  end
end

passed = 0
failed = 0

puts "=" * 80
puts "Testing stringify_on option"
puts "=" * 80
puts

# Test 1: Basic stringification with arrays
puts "Test 1: Basic stringification with arrays"
input = { 'columns' => [{ 'one' => 1, 'two' => [2] }] }
result = Toon.encode(input, stringify_on: 'columns')
expected = "columns[1]{one,two}:\n  1,\"[2]\""
test("Basic array stringification", result, expected) ? passed += 1 : failed += 1
puts

# Test 2: Basic stringification with hashes
puts "Test 2: Basic stringification with hashes"
input = { 'columns' => [{ 'one' => 1, 'three' => { 'three' => 3 } }] }
result = Toon.encode(input, stringify_on: 'columns')
expected = "columns[1]{one,three}:\n  1,\"{\\\"three\\\"=>3}\""
test("Basic hash stringification", result, expected) ? passed += 1 : failed += 1
puts

# Test 3: Stringifies both arrays and hashes
puts "Test 3: Stringifies both arrays and hashes"
input = { 'columns' => [{ 'one' => 1, 'two' => [2], 'three' => { 'three' => 3 } }] }
result = Toon.encode(input, stringify_on: 'columns')
expected = "columns[1]{one,two,three}:\n  1,\"[2]\",\"{\\\"three\\\"=>3}\""
test("Both arrays and hashes", result, expected) ? passed += 1 : failed += 1
puts

# Test 4: Keeps strings as-is
puts "Test 4: Keeps strings as-is"
input = { 'columns' => [{ 'id' => 1, 'name' => 'test' }] }
result = Toon.encode(input, stringify_on: 'columns')
expected = "columns[1]{id,name}:\n  1,test"
test("String preservation", result, expected) ? passed += 1 : failed += 1
puts

# Test 5: Keeps numbers as-is
puts "Test 5: Keeps numbers as-is"
input = { 'columns' => [{ 'int' => 42, 'float' => 3.14, 'negative' => -7 }] }
result = Toon.encode(input, stringify_on: 'columns')
expected = "columns[1]{int,float,negative}:\n  42,3.14,-7"
test("Number preservation", result, expected) ? passed += 1 : failed += 1
puts

# Test 6: Keeps booleans as-is
puts "Test 6: Keeps booleans as-is"
input = { 'columns' => [{ 'yes' => true, 'no' => false }] }
result = Toon.encode(input, stringify_on: 'columns')
expected = "columns[1]{yes,no}:\n  true,false"
test("Boolean preservation", result, expected) ? passed += 1 : failed += 1
puts

# Test 7: Keeps nil as-is
puts "Test 7: Keeps nil as-is"
input = { 'columns' => [{ 'id' => 1, 'value' => nil }] }
result = Toon.encode(input, stringify_on: 'columns')
expected = "columns[1]{id,value}:\n  1,null"
test("Nil preservation", result, expected) ? passed += 1 : failed += 1
puts

# Test 8: Does not modify when stringify_on is nil
puts "Test 8: Does not modify when stringify_on is nil"
input = { 'columns' => [{ 'one' => 1, 'two' => [2] }] }
result = Toon.encode(input, stringify_on: nil)
expected = "columns[1]:\n  - one: 1\n    two[1]: 2"
test("No modification when stringify_on is nil", result, expected) ? passed += 1 : failed += 1
puts

# Test 9: Does not modify when key does not exist
puts "Test 9: Does not modify when key does not exist"
input = { 'columns' => [{ 'one' => 1, 'two' => [2] }] }
result = Toon.encode(input, stringify_on: 'nonexistent')
expected = "columns[1]:\n  - one: 1\n    two[1]: 2"
test("No modification when key does not exist", result, expected) ? passed += 1 : failed += 1
puts

# Test 10: Handles empty arrays
puts "Test 10: Handles empty arrays"
input = { 'columns' => [] }
result = Toon.encode(input, stringify_on: 'columns')
expected = "columns[0]:"
test("Empty array handling", result, expected) ? passed += 1 : failed += 1
puts

# Test 11: Handles empty arrays as values
puts "Test 11: Handles empty arrays as values"
input = { 'columns' => [{ 'id' => 1, 'data' => [] }] }
result = Toon.encode(input, stringify_on: 'columns')
expected = "columns[1]{id,data}:\n  1,\"[]\""
test("Empty array value handling", result, expected) ? passed += 1 : failed += 1
puts

# Test 12: Handles empty hashes as values
puts "Test 12: Handles empty hashes as values"
input = { 'columns' => [{ 'id' => 1, 'data' => {} }] }
result = Toon.encode(input, stringify_on: 'columns')
expected = "columns[1]{id,data}:\n  1,\"{}\""
test("Empty hash value handling", result, expected) ? passed += 1 : failed += 1
puts

# Test 13: Works with normalize_on (normalize first, then stringify)
puts "Test 13: Works with normalize_on (normalize first, then stringify)"
input = {
  'columns' => [
    { 'one' => 1 },
    { 'one' => 1, 'two' => [2] }
  ]
}
result = Toon.encode(input, normalize_on: 'columns', stringify_on: 'columns')
expected = "columns[2]{one,two}:\n  1,null\n  1,\"[2]\""
test("normalize_on then stringify_on", result, expected) ? passed += 1 : failed += 1
puts

# Test 14: Works with delimiter option
puts "Test 14: Works with delimiter option"
input = { 'columns' => [{ 'one' => 1, 'two' => [2] }] }
result = Toon.encode(input, stringify_on: 'columns', delimiter: '|')
expected = "columns[1|]{one|two}:\n  1|\"[2]\""
test("Works with delimiter", result, expected) ? passed += 1 : failed += 1
puts

# Test 15: Works with length_marker option
puts "Test 15: Works with length_marker option"
input = { 'columns' => [{ 'one' => 1, 'two' => [2] }] }
result = Toon.encode(input, stringify_on: 'columns', length_marker: '#')
expected = "columns[#1]{one,two}:\n  1,\"[2]\""
test("Works with length_marker", result, expected) ? passed += 1 : failed += 1
puts

# Test 16: Works with indent option
puts "Test 16: Works with indent option"
input = { 'columns' => [{ 'one' => 1, 'two' => [2] }] }
result = Toon.encode(input, stringify_on: 'columns', indent: 4)
expected = "columns[1]{one,two}:\n    1,\"[2]\""
test("Works with indent", result, expected) ? passed += 1 : failed += 1
puts

# Test 17: Multiple hashes in the array
puts "Test 17: Multiple hashes in the array"
input = {
  'columns' => [
    { 'id' => 1, 'data' => [1, 2, 3] },
    { 'id' => 2, 'data' => { 'a' => 1 } }
  ]
}
result = Toon.encode(input, stringify_on: 'columns')
expected = "columns[2]{id,data}:\n  1,\"[1, 2, 3]\"\n  2,\"{\\\"a\\\"=>1}\""
test("Multiple hashes in array", result, expected) ? passed += 1 : failed += 1
puts

# Test 18: Nested arrays
puts "Test 18: Nested arrays"
input = { 'columns' => [{ 'id' => 1, 'matrix' => [[1, 2], [3, 4]] }] }
result = Toon.encode(input, stringify_on: 'columns')
expected = "columns[1]{id,matrix}:\n  1,\"[[1, 2], [3, 4]]\""
test("Nested arrays", result, expected) ? passed += 1 : failed += 1
puts

# Test 19: All options combined
puts "Test 19: All options combined"
input = {
  'columns' => [
    { 'one' => 1 },
    { 'one' => 1, 'two' => [2], 'three' => { 'x' => 3 } }
  ]
}
result = Toon.encode(
  input,
  normalize_on: 'columns',
  stringify_on: 'columns',
  delimiter: '|',
  length_marker: '#',
  indent: 4
)
# After normalize: first hash gets three: {"x" => nil} (nested hash structure)
# After stringify: {"x" => nil} becomes string "{\"x\"=>nil}"
expected = "columns[#2|]{one|two|three}:\n    1|null|\"{\\\"x\\\"=>nil}\"\n    1|\"[2]\"|\"{\\\"x\\\"=>3}\""
test("All options combined", result, expected) ? passed += 1 : failed += 1
puts

# Test 20: Execution order (normalize then stringify)
puts "Test 20: Execution order (normalize then stringify)"
input = {
  'columns' => [
    { 'one' => 1, 'two' => { 'a' => 1 } },
    { 'two' => { 'a' => 1, 'b' => 2 } }
  ]
}
result = Toon.encode(input, normalize_on: 'columns', stringify_on: 'columns')
expected = "columns[2]{one,two}:\n  1,\"{\\\"a\\\"=>1, \\\"b\\\"=>nil}\"\n  null,\"{\\\"a\\\"=>1, \\\"b\\\"=>2}\""
test("Execution order preserved", result, expected) ? passed += 1 : failed += 1
puts

puts "=" * 80
puts "Test Summary"
puts "=" * 80
puts "Passed: #{passed}"
puts "Failed: #{failed}"
puts "Total:  #{passed + failed}"
puts

if failed == 0
  puts "All tests passed!"
  exit 0
else
  puts "Some tests failed!"
  exit 1
end
