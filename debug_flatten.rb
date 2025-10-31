#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'lib/toon'

data = {
  "items" => [
    { "one" => { "two" => [1, 2] } },
    { "one" => { "two" => [3, 4], "three" => { "four" => 5 } } }
  ]
}

puts "Original:"
p data

puts "\nEncoded with flatten_on:"
encoded = Toon.encode(data, flatten_on: "items")
puts encoded

puts "\nTrying to decode:"
begin
  decoded = Toon.decode(encoded, unflatten_on: "items")
  p decoded
rescue => e
  puts "ERROR: #{e.message}"
  puts e.backtrace.first(5)
end
