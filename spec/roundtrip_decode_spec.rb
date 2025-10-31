# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Toon.decode with inverse operations' do
  describe 'destringify_on' do
    it 'converts stringified arrays back to arrays' do
      input = { "items" => [{ "one" => 1, "two" => "[2]", "three" => '{"three"=>3}' }] }
      toon = Toon.encode(input)
      decoded = Toon.decode(toon, destringify_on: "items")

      expected = { "items" => [{ "one" => 1, "two" => [2], "three" => { "three" => 3 } }] }
      expect(decoded).to eq(expected)
    end

    it 'converts stringified hashes back to hashes' do
      input = { "items" => [{ "id" => 1, "metadata" => '{"key"=>"value"}' }] }
      toon = Toon.encode(input)
      decoded = Toon.decode(toon, destringify_on: "items")

      expected = { "items" => [{ "id" => 1, "metadata" => { "key" => "value" } }] }
      expect(decoded).to eq(expected)
    end

    it 'leaves primitives unchanged' do
      input = { "items" => [{ "str" => "hello", "num" => 42, "bool" => true, "nil" => nil }] }
      toon = Toon.encode(input)
      decoded = Toon.decode(toon, destringify_on: "items")

      expect(decoded).to eq(input)
    end

    it 'handles complex nested arrays' do
      input = { "items" => [{ "data" => '[[1, 2], [3, 4]]' }] }
      toon = Toon.encode(input)
      decoded = Toon.decode(toon, destringify_on: "items")

      expected = { "items" => [{ "data" => [[1, 2], [3, 4]] }] }
      expect(decoded).to eq(expected)
    end

    it 'handles strings that look like arrays but are not' do
      input = { "items" => [{ "text" => "[not an array" }] }
      toon = Toon.encode(input)
      decoded = Toon.decode(toon, destringify_on: "items")

      expect(decoded).to eq(input)
    end
  end

  describe 'unflatten_on' do
    it 'converts flattened keys back to nested hashes' do
      input = { "items" => [{ "one/two" => 2, "one/three/four" => 5 }] }
      toon = Toon.encode(input)
      decoded = Toon.decode(toon, unflatten_on: "items")

      expected = { "items" => [{ "one" => { "two" => 2, "three" => { "four" => 5 } } }] }
      expect(decoded).to eq(expected)
    end

    it 'handles single-level keys' do
      input = { "items" => [{ "simple" => 1, "another" => 2 }] }
      toon = Toon.encode(input)
      decoded = Toon.decode(toon, unflatten_on: "items")

      expect(decoded).to eq(input)
    end

    it 'handles deeply nested paths' do
      input = { "items" => [{ "a/b/c/d/e" => 5 }] }
      toon = Toon.encode(input)
      decoded = Toon.decode(toon, unflatten_on: "items")

      expected = { "items" => [{ "a" => { "b" => { "c" => { "d" => { "e" => 5 } } } } }] }
      expect(decoded).to eq(expected)
    end

    it 'merges overlapping paths' do
      input = { "items" => [{ "user/name" => "Ada", "user/id" => 123 }] }
      toon = Toon.encode(input)
      decoded = Toon.decode(toon, unflatten_on: "items")

      expected = { "items" => [{ "user" => { "name" => "Ada", "id" => 123 } }] }
      expect(decoded).to eq(expected)
    end
  end

  describe 'denormalize_on' do
    it 'removes nil values from hashes' do
      input = { "items" => [{ "one" => 1, "two" => nil }, { "one" => 1, "two" => 2 }] }
      toon = Toon.encode(input)
      decoded = Toon.decode(toon, denormalize_on: "items")

      expected = { "items" => [{ "one" => 1 }, { "one" => 1, "two" => 2 }] }
      expect(decoded).to eq(expected)
    end

    it 'keeps false and 0 values' do
      input = { "items" => [{ "bool" => false, "num" => 0, "nil" => nil }] }
      toon = Toon.encode(input)
      decoded = Toon.decode(toon, denormalize_on: "items")

      expected = { "items" => [{ "bool" => false, "num" => 0 }] }
      expect(decoded).to eq(expected)
    end

    it 'removes nested nil values' do
      input = { "items" => [{ "outer" => { "inner" => nil, "value" => 1 } }] }
      toon = Toon.encode(input)
      decoded = Toon.decode(toon, denormalize_on: "items")

      expected = { "items" => [{ "outer" => { "value" => 1 } }] }
      expect(decoded).to eq(expected)
    end

    it 'removes empty nested hashes after denormalization' do
      input = { "items" => [{ "outer" => { "inner" => nil } }] }
      toon = Toon.encode(input)
      decoded = Toon.decode(toon, denormalize_on: "items")

      expected = { "items" => [{}] }
      expect(decoded).to eq(expected)
    end
  end

  describe 'roundtrip with stringify_on' do
    it 'roundtrips with stringify_on and destringify_on' do
      original = { "items" => [
        { "id" => 1, "data" => [1, 2, 3] },
        { "id" => 2, "data" => [4, 5] }
      ] }

      encoded = Toon.encode(original, stringify_on: "items")
      decoded = Toon.decode(encoded, destringify_on: "items")

      expect(decoded).to eq(original)
    end

    it 'roundtrips with nested hashes' do
      original = { "items" => [
        { "id" => 1, "meta" => { "key" => "value" } },
        { "id" => 2, "meta" => { "another" => "thing" } }
      ] }

      encoded = Toon.encode(original, stringify_on: "items")
      decoded = Toon.decode(encoded, destringify_on: "items")

      expect(decoded).to eq(original)
    end
  end

  describe 'roundtrip with flatten_on' do
    it 'roundtrips with flatten_on and unflatten_on' do
      original = { "items" => [
        { "one" => { "two" => [1, 2] } },
        { "one" => { "two" => [3, 4], "three" => { "four" => 5 } } }
      ] }

      encoded = Toon.encode(original, flatten_on: "items")
      decoded = Toon.decode(encoded, unflatten_on: "items")

      expect(decoded).to eq(original)
    end

    it 'roundtrips with deeply nested structures' do
      original = { "items" => [
        { "a" => { "b" => { "c" => 1 } } },
        { "a" => { "b" => { "d" => 2 } } }
      ] }

      encoded = Toon.encode(original, flatten_on: "items")
      decoded = Toon.decode(encoded, unflatten_on: "items")

      expect(decoded).to eq(original)
    end
  end

  describe 'roundtrip with normalize_on' do
    it 'roundtrips with normalize_on and denormalize_on' do
      original = { "items" => [
        { "one" => 1 },
        { "one" => 1, "two" => 2 }
      ] }

      encoded = Toon.encode(original, normalize_on: "items")
      decoded = Toon.decode(encoded, denormalize_on: "items")

      expect(decoded).to eq(original)
    end

    it 'roundtrips with nested structures' do
      original = { "items" => [
        { "outer" => { "value" => 1 } },
        { "outer" => { "value" => 2, "extra" => 3 } }
      ] }

      encoded = Toon.encode(original, normalize_on: "items")
      decoded = Toon.decode(encoded, denormalize_on: "items")

      expect(decoded).to eq(original)
    end
  end

  describe 'roundtrip with all three operations' do
    it 'roundtrips the example from the task description' do
      data = {
        "items" => [
          { "one" => { "two" => [1, 2] } },
          { "one" => { "two" => [3, 4], "three" => { "four" => 5 } } }
        ]
      }

      encoded = Toon.encode(data, normalize_on: "items", flatten_on: "items", stringify_on: "items")
      decoded = Toon.decode(encoded, destringify_on: "items", unflatten_on: "items", denormalize_on: "items")

      expect(decoded).to eq(data)
    end

    it 'roundtrips complex nested data' do
      data = {
        "items" => [
          { "user" => { "name" => "Ada", "tags" => ["ruby", "programming"] } },
          { "user" => { "name" => "Bob", "tags" => ["python"], "active" => true } }
        ]
      }

      encoded = Toon.encode(data, normalize_on: "items", flatten_on: "items", stringify_on: "items")
      decoded = Toon.decode(encoded, destringify_on: "items", unflatten_on: "items", denormalize_on: "items")

      expect(decoded).to eq(data)
    end

    it 'roundtrips with mixed data types' do
      data = {
        "items" => [
          { "id" => 1, "meta" => { "count" => 5, "items" => [1, 2, 3] } },
          { "id" => 2, "meta" => { "count" => 10, "items" => [4, 5, 6], "extra" => { "deep" => "value" } } }
        ]
      }

      encoded = Toon.encode(data, normalize_on: "items", flatten_on: "items", stringify_on: "items")
      decoded = Toon.decode(encoded, destringify_on: "items", unflatten_on: "items", denormalize_on: "items")

      expect(decoded).to eq(data)
    end

    it 'roundtrips with empty arrays and hashes' do
      data = {
        "items" => [
          { "id" => 1, "data" => [] },
          { "id" => 2, "data" => [], "meta" => {} }
        ]
      }

      encoded = Toon.encode(data, normalize_on: "items", flatten_on: "items", stringify_on: "items")
      decoded = Toon.decode(encoded, destringify_on: "items", unflatten_on: "items", denormalize_on: "items")

      expect(decoded).to eq(data)
    end
  end

  describe 'partial operations' do
    it 'allows using only destringify_on' do
      data = { "items" => [{ "id" => 1, "data" => [1, 2, 3] }] }

      encoded = Toon.encode(data, stringify_on: "items")
      decoded = Toon.decode(encoded, destringify_on: "items")

      expect(decoded).to eq(data)
    end

    it 'allows using only unflatten_on' do
      data = { "items" => [{ "one" => { "two" => 2 } }] }

      encoded = Toon.encode(data, flatten_on: "items")
      decoded = Toon.decode(encoded, unflatten_on: "items")

      expect(decoded).to eq(data)
    end

    it 'allows using only denormalize_on' do
      data = { "items" => [{ "id" => 1 }, { "id" => 2, "name" => "Ada" }] }

      encoded = Toon.encode(data, normalize_on: "items")
      decoded = Toon.decode(encoded, denormalize_on: "items")

      expect(decoded).to eq(data)
    end

    it 'allows combining normalize and flatten without stringify' do
      data = { "items" => [
        { "one" => { "two" => 2 } },
        { "one" => { "two" => 3, "three" => 4 } }
      ] }

      encoded = Toon.encode(data, normalize_on: "items", flatten_on: "items")
      decoded = Toon.decode(encoded, unflatten_on: "items", denormalize_on: "items")

      expect(decoded).to eq(data)
    end

    it 'allows combining flatten and stringify without normalize' do
      data = { "items" => [
        { "one" => { "two" => [1, 2] } },
        { "one" => { "two" => [3, 4] } }
      ] }

      encoded = Toon.encode(data, flatten_on: "items", stringify_on: "items")
      decoded = Toon.decode(encoded, destringify_on: "items", unflatten_on: "items")

      expect(decoded).to eq(data)
    end
  end

  describe 'edge cases' do
    it 'handles keys that do not exist' do
      data = { "other" => [{ "id" => 1 }] }

      encoded = Toon.encode(data)
      decoded = Toon.decode(encoded, destringify_on: "items", unflatten_on: "items", denormalize_on: "items")

      expect(decoded).to eq(data)
    end

    it 'handles non-hash root values' do
      data = [1, 2, 3]

      encoded = Toon.encode(data)
      decoded = Toon.decode(encoded, destringify_on: "items")

      expect(decoded).to eq(data)
    end

    it 'handles empty arrays' do
      data = { "items" => [] }

      encoded = Toon.encode(data, normalize_on: "items", flatten_on: "items", stringify_on: "items")
      decoded = Toon.decode(encoded, destringify_on: "items", unflatten_on: "items", denormalize_on: "items")

      expect(decoded).to eq(data)
    end

    it 'handles strings with forward slashes that should not be unflattened' do
      # When not using flatten_on, strings with "/" should remain unchanged
      data = { "items" => [{ "path" => "folder/file.txt" }] }

      encoded = Toon.encode(data)
      decoded = Toon.decode(encoded)

      expect(decoded).to eq(data)
    end
  end
end
