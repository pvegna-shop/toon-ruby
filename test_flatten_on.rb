#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'lib/toon'

def test_case(description, input, options, expected)
  puts "Testing: #{description}"
  result = Toon.encode(input, **options)
  if result == expected
    puts "  PASS"
    true
  else
    puts "  FAIL"
    puts "  Expected: #{expected.inspect}"
    puts "  Got:      #{result.inspect}"
    false
  end
end

puts "Running flatten_on feature tests..."
puts "=" * 80

all_passed = true

# Test 1: Simple nested hash
all_passed &= test_case(
  "Simple nested hash",
  { 'items' => [{ 'one' => { 'two' => 2 } }] },
  { flatten_on: 'items' },
  "items[1]{\"one/two\"}:\n  2"
)

# Test 2: Multiple levels
all_passed &= test_case(
  "Multiple levels of nesting",
  { 'items' => [{ 'a' => { 'b' => { 'c' => 3 } } }] },
  { flatten_on: 'items' },
  "items[1]{\"a/b/c\"}:\n  3"
)

# Test 3: Mixed values
all_passed &= test_case(
  "Mixed hash and non-hash values",
  { 'items' => [{ 'one' => 1, 'two' => { 'three' => 3 } }] },
  { flatten_on: 'items' },
  "items[1]{one,\"two/three\"}:\n  1,3"
)

# Test 4: Arrays not flattened
all_passed &= test_case(
  "Arrays should NOT be flattened",
  { 'items' => [{ 'one' => [1, 2], 'two' => { 'three' => 3 } }] },
  { flatten_on: 'items' },
  "items[1]:\n  - one[2]: 1,2\n    \"two/three\": 3"
)

# Test 5: Multiple hashes
all_passed &= test_case(
  "Multiple hashes in array",
  { 'items' => [{ 'a' => { 'b' => 1 } }, { 'a' => { 'b' => 2 } }] },
  { flatten_on: 'items' },
  "items[2]{\"a/b\"}:\n  1\n  2"
)

# Test 6: With normalize_on
all_passed &= test_case(
  "With normalize_on (normalize → flatten)",
  {
    'items' => [
      { 'one' => { 'two' => 2 } },
      { 'one' => { 'two' => 2, 'three' => 3 } }
    ]
  },
  { normalize_on: 'items', flatten_on: 'items' },
  "items[2]{\"one/two\",\"one/three\"}:\n  2,null\n  2,3"
)

# Test 7: With stringify_on
all_passed &= test_case(
  "With stringify_on (flatten → stringify)",
  { 'items' => [{ 'one' => { 'two' => [1, 2, 3] } }] },
  { flatten_on: 'items', stringify_on: 'items' },
  "items[1]{\"one/two\"}:\n  \"[1, 2, 3]\""
)

# Test 8: All three options
all_passed &= test_case(
  "All three options (normalize → flatten → stringify)",
  {
    'items' => [
      { 'one' => { 'two' => [1, 2] } },
      { 'one' => { 'two' => [3, 4], 'three' => { 'four' => 5 } } }
    ]
  },
  { normalize_on: 'items', flatten_on: 'items', stringify_on: 'items' },
  "items[2]{\"one/two\",\"one/three/four\"}:\n  \"[1, 2]\",null\n  \"[3, 4]\",5"
)

# Test 9: With delimiter
all_passed &= test_case(
  "With delimiter option",
  { 'items' => [{ 'one' => { 'two' => 2 } }] },
  { flatten_on: 'items', delimiter: '|' },
  "items[1|]{\"one/two\"}:\n  2"
)

# Test 10: With length_marker
all_passed &= test_case(
  "With length_marker option",
  { 'items' => [{ 'one' => { 'two' => 2 } }] },
  { flatten_on: 'items', length_marker: '#' },
  "items[#1]{\"one/two\"}:\n  2"
)

# Test 11: flatten_on is nil (no flattening)
all_passed &= test_case(
  "flatten_on is nil (no flattening)",
  { 'items' => [{ 'one' => { 'two' => 2 } }] },
  { flatten_on: nil },
  "items[1]:\n  - one:\n      two: 2"
)

# Test 12: flatten_on key doesn't exist
all_passed &= test_case(
  "flatten_on key doesn't exist",
  { 'items' => [{ 'one' => { 'two' => 2 } }] },
  { flatten_on: 'nonexistent' },
  "items[1]:\n  - one:\n      two: 2"
)

puts "=" * 80
if all_passed
  puts "All tests PASSED!"
  exit 0
else
  puts "Some tests FAILED!"
  exit 1
end
