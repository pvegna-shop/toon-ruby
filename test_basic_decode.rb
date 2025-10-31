#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'lib/toon'

# Test basic nested hash encoding/decoding without any special options
puts "Testing basic nested hash encoding/decoding"
puts "=" * 60

data = { "items" => [{ "outer" => { "inner" => nil, "value" => 1 } }] }
puts "Original: #{data.inspect}"

# Encode without any options
encoded = Toon.encode(data)
puts "\nEncoded:"
puts encoded

# Decode without any options
decoded = Toon.decode(encoded)
puts "\nDecoded: #{decoded.inspect}"

puts "\nAre they equal? #{decoded == data}"

# Let's also test with a simpler structure
puts "\n" + "=" * 60
puts "\nSimpler test:"
data2 = { "outer" => { "inner" => nil, "value" => 1 } }
puts "Original: #{data2.inspect}"

encoded2 = Toon.encode(data2)
puts "\nEncoded:"
puts encoded2

decoded2 = Toon.decode(encoded2)
puts "\nDecoded: #{decoded2.inspect}"

puts "\nAre they equal? #{decoded2 == data2}"
