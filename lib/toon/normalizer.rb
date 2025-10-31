# frozen_string_literal: true

require 'set'
require 'date'

module Toon
  module Normalizer
    module_function

    # Normalization (unknown → JSON-compatible value)
    def normalize_value(value)
      case value
      when nil
        nil
      when String, TrueClass, FalseClass
        value
      when Numeric
        # Float special cases
        if value.is_a?(Float)
          # -0.0 becomes 0
          return 0 if value.zero? && (1.0 / value).negative?
          # NaN and Infinity become nil
          return nil unless value.finite?
        end
        value
      when Symbol
        value.to_s
      when Time
        value.utc.strftime('%Y-%m-%dT%H:%M:%SZ')
      when ->(v) { v.respond_to?(:iso8601) && !v.is_a?(Date) }
        value.iso8601
      when Date
        value.to_time.utc.iso8601
      when Array
        value.map { |v| normalize_value(v) }
      when Set
        value.to_a.map { |v| normalize_value(v) }
      when Hash
        value.each_with_object({}) { |(k, v), h| h[k.to_s] = normalize_value(v) }
      else
        # Fallback: anything else becomes nil (functions, etc.)
        nil
      end
    end

    # Type guards
    def json_primitive?(value)
      value.nil? ||
        value.is_a?(String) ||
        value.is_a?(Numeric) ||
        value.is_a?(TrueClass) ||
        value.is_a?(FalseClass)
    end

    def json_array?(value)
      value.is_a?(Array)
    end

    def json_object?(value)
      value.is_a?(Hash)
    end

    # Array type detection
    def array_of_primitives?(value)
      return false unless value.is_a?(Array)
      value.all? { |item| json_primitive?(item) }
    end

    def array_of_arrays?(value)
      return false unless value.is_a?(Array)
      value.all? { |item| json_array?(item) }
    end

    def array_of_objects?(value)
      return false unless value.is_a?(Array)
      value.all? { |item| json_object?(item) }
    end

    # Normalize an array of hashes by ensuring all hashes have the same keys
    # Recursively normalizes nested hashes as well
    def normalize_array_of_hashes(array)
      return array unless array.is_a?(Array)
      return array if array.empty?
      return array unless array.all? { |item| item.is_a?(Hash) }

      # Collect all keys recursively
      key_structure = collect_all_keys_recursive(array)

      # Normalize each hash in the array
      array.map { |hash| normalize_hash(hash, key_structure) }
    end

    # Collect all keys that appear in any hash in the array, recursively
    # Returns a hash structure representing all keys and their nested structures
    def collect_all_keys_recursive(array)
      return {} unless array.is_a?(Array)

      key_structure = {}

      array.each do |item|
        next unless item.is_a?(Hash)

        item.each do |key, value|
          if value.is_a?(Hash)
            # Recursively collect keys from nested hashes
            if key_structure[key].is_a?(Hash)
              key_structure[key] = merge_key_structures(key_structure[key], collect_all_keys_from_hash(value))
            else
              key_structure[key] = collect_all_keys_from_hash(value)
            end
          else
            # Mark as non-hash value if not already marked as hash structure
            key_structure[key] = {} unless key_structure[key].is_a?(Hash)
          end
        end
      end

      key_structure
    end

    # Collect all keys from a single hash recursively
    def collect_all_keys_from_hash(hash)
      return {} unless hash.is_a?(Hash)

      key_structure = {}

      hash.each do |key, value|
        if value.is_a?(Hash)
          key_structure[key] = collect_all_keys_from_hash(value)
        else
          key_structure[key] = {}
        end
      end

      key_structure
    end

    # Merge two key structures together
    def merge_key_structures(struct1, struct2)
      result = struct1.dup

      struct2.each do |key, nested_struct|
        if result[key].is_a?(Hash) && nested_struct.is_a?(Hash)
          result[key] = merge_key_structures(result[key], nested_struct)
        else
          result[key] = nested_struct
        end
      end

      result
    end

    # Normalize a single hash according to the key structure
    def normalize_hash(hash, key_structure)
      result = {}

      key_structure.each do |key, nested_structure|
        if hash.key?(key)
          value = hash[key]
          if value.is_a?(Hash) && nested_structure.is_a?(Hash) && !nested_structure.empty?
            # Recursively normalize nested hash
            result[key] = normalize_hash(value, nested_structure)
          else
            result[key] = value
          end
        else
          # Key is missing, add it with appropriate default value
          if nested_structure.is_a?(Hash) && !nested_structure.empty?
            # This should be a nested hash, create one with nil values
            result[key] = normalize_hash({}, nested_structure)
          else
            result[key] = nil
          end
        end
      end

      result
    end
  end
end
