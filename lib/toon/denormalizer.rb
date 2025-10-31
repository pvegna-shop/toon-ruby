# frozen_string_literal: true

module Toon
  module Denormalizer
    module_function

    # Denormalize an array of hashes
    # Remove nil values that were added during normalization
    # Recursively processes nested hashes as well
    #
    # @param array [Array] An array of hashes
    # @return [Array] Array with nil values removed from hashes
    def denormalize_array_of_hashes(array)
      return array unless array.is_a?(Array)
      return array if array.empty?
      return array unless array.all? { |item| item.is_a?(Hash) }

      array.map { |hash| denormalize_hash(hash) }
    end

    # Denormalize a single hash
    # Remove all keys with nil values
    # Recursively processes nested hashes
    #
    # @param hash [Hash] The hash to denormalize
    # @return [Hash] The hash with nil values removed
    def denormalize_hash(hash)
      return hash unless hash.is_a?(Hash)

      hash.each_with_object({}) do |(key, value), result|
        # Skip nil values
        next if value.nil?

        # Recursively denormalize nested hashes
        if value.is_a?(Hash)
          denormalized = denormalize_hash(value)
          # Only include the nested hash if it's not empty after denormalization
          result[key] = denormalized unless denormalized.empty?
        else
          result[key] = value
        end
      end
    end
  end
end
