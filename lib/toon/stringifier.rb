# frozen_string_literal: true

module Toon
  module Stringifier
    module_function

    # Check if a value is a primitive type that should not be stringified
    def primitive?(value)
      value.nil? ||
        value.is_a?(String) ||
        value.is_a?(Numeric) ||
        value.is_a?(TrueClass) ||
        value.is_a?(FalseClass)
    end

    # Stringify non-primitive values in a single hash
    # Primitives remain unchanged, arrays and hashes are converted to strings
    def stringify_hash(hash)
      return hash unless hash.is_a?(Hash)

      hash.each_with_object({}) do |(key, value), result|
        result[key] = if primitive?(value)
                        value
                      else
                        value.inspect
                      end
      end
    end

    # Stringify an array of hashes
    # For each hash in the array, convert non-primitive values to strings
    def stringify_array_of_hashes(array)
      return array unless array.is_a?(Array)
      return array if array.empty?
      return array unless array.all? { |item| item.is_a?(Hash) }

      array.map { |hash| stringify_hash(hash) }
    end
  end
end
