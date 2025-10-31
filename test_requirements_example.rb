#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'lib/toon'

puts "=" * 80
puts "Testing the EXACT example from requirements"
puts "=" * 80
puts

puts "Input:"
input = { "columns" => [{ "one" => 1, "two" => [2], "three" => { "three" => 3 } }] }
puts input.inspect
puts

puts "Toon.encode(input, stringify_on: 'columns'):"
result = Toon.encode(input, stringify_on: "columns")
puts result
puts

puts "Expected from requirements:"
puts 'columns[1]{one,two,three}:'
puts '  1,"[2]","{\"three\"=>3}"'
puts

# Verify it matches
expected = "columns[1]{one,two,three}:\n  1,\"[2]\",\"{\\\"three\\\"=>3}\""
if result == expected
  puts "✓ PASS: Output matches requirements exactly!"
else
  puts "✗ FAIL: Output does not match"
  puts "Expected: #{expected.inspect}"
  puts "Got:      #{result.inspect}"
end
