#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'lib/toon'

# Test what happens with nested hashes during normalization
puts "Testing nested hash normalization"
puts "=" * 60

data = { "items" => [{ "outer" => { "inner" => nil, "value" => 1 } }] }
puts "Original: #{data.inspect}"

# What does normalize do?
normalized = data.dup
normalized["items"] = Toon::Normalizer.normalize_array_of_hashes(normalized["items"])
puts "\nAfter normalize: #{normalized.inspect}"

# Now encode it
encoded = Toon.encode(data, normalize_on: "items")
puts "\nEncoded:"
puts encoded

# Decode it
decoded = Toon.decode(encoded)
puts "\nDecoded (no denormalize): #{decoded.inspect}"

# The issue is that nested hashes are being fully decoded as nested hashes
# but the normalizer doesn't touch nested structures
# So when we denormalize, we need to handle nested hashes recursively

puts "\n" + "=" * 60
puts "\nTesting denormalizer directly"

test_hash = { "outer" => { "inner" => nil, "value" => 1 } }
puts "Test hash: #{test_hash.inspect}"

denormalized = Toon::Denormalizer.denormalize_hash(test_hash)
puts "After denormalize_hash: #{denormalized.inspect}"

# The expected result is {"outer" => {"value" => 1}}
expected = { "outer" => { "value" => 1 } }
puts "Expected: #{expected.inspect}"
puts "Match? #{denormalized == expected}"
