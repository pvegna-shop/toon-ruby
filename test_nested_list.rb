#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'lib/toon'

# Test from the spec that works
puts "Test from spec (should work):"
toon1 = "items[1]:\n  - id: 1\n    nested:\n      x: 1"
puts "TOON input:"
puts toon1
decoded1 = Toon.decode(toon1)
puts "Decoded: #{decoded1.inspect}"
expected1 = { 'items' => [{ 'id' => 1, 'nested' => { 'x' => 1 } }] }
puts "Expected: #{expected1.inspect}"
puts "Match? #{decoded1 == expected1}"

puts "\n" + "=" * 60
puts "\nOur problematic case:"
toon2 = "items[1]:\n  - outer:\n      inner: null\n      value: 1"
puts "TOON input:"
puts toon2
decoded2 = Toon.decode(toon2)
puts "Decoded: #{decoded2.inspect}"
expected2 = { "items" => [{ "outer" => { "inner" => nil, "value" => 1 } }] }
puts "Expected: #{expected2.inspect}"
puts "Match? #{decoded2 == expected2}"

puts "\n" + "=" * 60
puts "\nTrying with non-null values:"
toon3 = "items[1]:\n  - outer:\n      inner: 5\n      value: 1"
puts "TOON input:"
puts toon3
decoded3 = Toon.decode(toon3)
puts "Decoded: #{decoded3.inspect}"
expected3 = { "items" => [{ "outer" => { "inner" => 5, "value" => 1 } }] }
puts "Expected: #{expected3.inspect}"
puts "Match? #{decoded3 == expected3}"

puts "\n" + "=" * 60
puts "\nTrying with only null value:"
toon4 = "items[1]:\n  - outer:\n      inner: null"
puts "TOON input:"
puts toon4
decoded4 = Toon.decode(toon4)
puts "Decoded: #{decoded4.inspect}"
expected4 = { "items" => [{ "outer" => { "inner" => nil } }] }
puts "Expected: #{expected4.inspect}"
puts "Match? #{decoded4 == expected4}"
