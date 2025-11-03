# frozen_string_literal: true

module Toon
  module Unflattener
    module_function

    # Unflatten an array of hashes
    # For each hash in the array, convert flattened keys back to nested structures
    #
    # @param array [Array] An array of hashes with flattened keys
    # @return [Array] Array with nested hash structures restored
    def unflatten_array_of_hashes(array)
      return array unless array.is_a?(Array)
      return array if array.empty?
      return array unless array.all? { |item| item.is_a?(Hash) }

      array.map { |hash| unflatten_hash(hash) }
    end

    # Unflatten a single hash
    # Convert keys with "." separators back to nested hash structures
    # Example: {"one.two" => 2, "one.three.four" => 5}
    #       => {"one" => {"two" => 2, "three" => {"four" => 5}}}
    #
    # @param hash [Hash] The hash to unflatten
    # @param sep [String] The separator used in flattened keys (default: ".")
    # @return [Hash] The nested hash structure
    def unflatten_hash(hash, sep = ".")
      return hash unless hash.is_a?(Hash)

      result = {}

      hash.each do |key, value|
        parts = key.to_s.split(sep)
        current = result

        # Navigate/create nested structure for all but the last part
        parts[0...-1].each do |part|
          current[part] ||= {}
          current = current[part]
        end

        # Set the final value
        current[parts.last] = value
      end

      result
    end
  end
end
