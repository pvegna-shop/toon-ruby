# typed: strong

# Public API for the toon-ruby gem
# This file is manually maintained to expose only the public interface
module Toon
  # Encode any value to TOON format
  #
  # @param input [Object] Any value to encode
  # @param indent [Integer] Number of spaces per indentation level (default: 2)
  # @param delimiter [String] Delimiter for array values and tabular rows (default: ',')
  # @param length_marker [String, false] Optional marker to prefix array lengths (default: false)
  # @param normalize_on [String, Symbol, nil] Optional key name to normalize array of hashes (default: nil)
  # @param flatten_on [String, Symbol, nil] Optional key name to flatten nested hashes in array of hashes (default: nil)
  # @param stringify_on [String, Symbol, nil] Optional key name to stringify non-primitives in array of hashes (default: nil)
  # @return [String] TOON-formatted string
  sig do
    params(
      input: T.untyped,
      indent: Integer,
      delimiter: String,
      length_marker: T.any(String, FalseClass),
      normalize_on: T.nilable(T.any(String, Symbol)),
      flatten_on: T.nilable(T.any(String, Symbol)),
      stringify_on: T.nilable(T.any(String, Symbol))
    ).returns(String)
  end
  def self.encode(input, indent: 2, delimiter: ",", length_marker: false, normalize_on: nil, flatten_on: nil, stringify_on: nil); end

  # Decode a TOON-formatted string to a Ruby value
  #
  # @param input [String] TOON-formatted string to decode
  # @param indent [Integer] Number of spaces per indentation level (default: 2)
  # @param strict [Boolean] When true, enforce strict validation of array lengths and tabular row counts (default: true)
  # @param destringify_on [String, Symbol, nil] Optional key name to destringify array of hashes (default: nil)
  # @param unflatten_on [String, Symbol, nil] Optional key name to unflatten nested hashes in array of hashes (default: nil)
  # @param denormalize_on [String, Symbol, nil] Optional key name to denormalize array of hashes (default: nil)
  # @return [Object] Decoded Ruby value (Hash, Array, or primitive)
  sig do
    params(
      input: String,
      indent: Integer,
      strict: T::Boolean,
      destringify_on: T.nilable(T.any(String, Symbol)),
      unflatten_on: T.nilable(T.any(String, Symbol)),
      denormalize_on: T.nilable(T.any(String, Symbol))
    ).returns(T.untyped)
  end
  def self.decode(input, indent: 2, strict: true, destringify_on: nil, unflatten_on: nil, denormalize_on: nil); end

  # Version constant
  VERSION = T.let("0.1.1", String)

  # Default delimiter for arrays
  DEFAULT_DELIMITER = T.let(",", String)
end
