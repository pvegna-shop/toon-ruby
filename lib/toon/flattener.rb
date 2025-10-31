# frozen_string_literal: true

module Toon
  module Flattener
    module_function

    # Flatten an array of hashes by recursively flattening nested hashes
    # within each hash in the array
    #
    # @param array [Array] An array of hashes
    # @return [Array] Array with all nested hashes flattened
    def flatten_array_of_hashes(array)
      return array unless array.is_a?(Array)
      return array if array.empty?
      return array unless array.all? { |item| item.is_a?(Hash) }

      array.map { |hash| flatten_hash(hash) }
    end

    # Recursively flatten a single hash
    # Converts nested hash structures like {"a" => {"b" => 1}} to {"a/b" => 1}
    # Only flattens Hash values, not Arrays
    #
    # @param hash [Hash] The hash to flatten
    # @param parent_key [String] The parent key path (used in recursion)
    # @param sep [String] The separator to use between nested keys (default: "/")
    # @return [Hash] The flattened hash
    def flatten_hash(hash, parent_key = "", sep = "/")
      return hash unless hash.is_a?(Hash)

      hash.each_with_object({}) do |(key, value), result|
        new_key = parent_key.empty? ? key.to_s : "#{parent_key}#{sep}#{key}"

        if value.is_a?(Hash)
          # Recursively flatten nested hash
          result.merge!(flatten_hash(value, new_key, sep))
        else
          # Keep non-hash values (including arrays) as-is
          result[new_key] = value
        end
      end
    end
  end
end
