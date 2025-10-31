# frozen_string_literal: true

module Toon
  module Destringifier
    module_function

    # Destringify an array of hashes
    # For each hash in the array, convert stringified arrays/hashes back to their Ruby objects
    #
    # @param array [Array] An array of hashes
    # @return [Array] Array with stringified values converted back to objects
    def destringify_array_of_hashes(array)
      return array unless array.is_a?(Array)
      return array if array.empty?
      return array unless array.all? { |item| item.is_a?(Hash) }

      array.map { |hash| destringify_hash(hash) }
    end

    # Destringify a single hash
    # Convert string representations of arrays and hashes back to their Ruby objects
    #
    # @param hash [Hash] The hash to destringify
    # @return [Hash] The hash with destringified values
    def destringify_hash(hash)
      return hash unless hash.is_a?(Hash)

      hash.each_with_object({}) do |(key, value), result|
        result[key] = destringify_value(value)
      end
    end

    # Destringify a single value
    # If the value is a string that looks like an array or hash, parse it back
    # Otherwise, return the value unchanged
    #
    # @param value [Object] The value to destringify
    # @return [Object] The destringified value or the original value
    def destringify_value(value)
      return value unless value.is_a?(String)

      # Try to parse as array or hash
      if value.start_with?('[') && value.end_with?(']')
        begin
          # Use eval in a safe context - the string came from our own stringify operation
          # which uses .inspect, so it should be safe
          parsed = eval(value)
          # Only return parsed value if it's actually an array
          return parsed if parsed.is_a?(Array)
        rescue StandardError
          # If parsing fails, keep as string
        end
      elsif value.start_with?('{') && value.end_with?('}')
        begin
          # Use eval in a safe context - the string came from our own stringify operation
          parsed = eval(value)
          # Only return parsed value if it's actually a hash
          return parsed if parsed.is_a?(Hash)
        rescue StandardError
          # If parsing fails, keep as string
        end
      end

      # Return unchanged if not an array/hash string or if parsing failed
      value
    end
  end
end
