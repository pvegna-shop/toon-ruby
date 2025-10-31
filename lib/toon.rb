# frozen_string_literal: true

require_relative 'toon/version'
require_relative 'toon/constants'
require_relative 'toon/writer'
require_relative 'toon/normalizer'
require_relative 'toon/flattener'
require_relative 'toon/stringifier'
require_relative 'toon/denormalizer'
require_relative 'toon/unflattener'
require_relative 'toon/destringifier'
require_relative 'toon/primitives'
require_relative 'toon/encoders'
require_relative 'toon/string_utils'
require_relative 'toon/literal_utils'
require_relative 'toon/scanner'
require_relative 'toon/parser'
require_relative 'toon/validation'
require_relative 'toon/decoders'

module Toon
  module_function

  # Encode any value to TOON format
  #
  # @param input [Object] Any value to encode
  # @param indent [Integer] Number of spaces per indentation level (default: 2)
  # @param delimiter [String] Delimiter for array values and tabular rows (default: ',')
  # @param length_marker [String, false] Optional marker to prefix array lengths (default: false)
  # @param normalize_on [String, nil] Optional key name to normalize array of hashes (default: nil)
  # @param flatten_on [String, nil] Optional key name to flatten nested hashes in array of hashes (default: nil)
  # @param stringify_on [String, nil] Optional key name to stringify non-primitives in array of hashes (default: nil)
  # @return [String] TOON-formatted string
  def encode(input, indent: 2, delimiter: DEFAULT_DELIMITER, length_marker: false, normalize_on: nil, flatten_on: nil, stringify_on: nil)
    # Apply normalization if normalize_on is specified
    if normalize_on && input.is_a?(Hash) && input.key?(normalize_on)
      input = input.dup
      input[normalize_on] = Normalizer.normalize_array_of_hashes(input[normalize_on])
    end

    # Apply flattening if flatten_on is specified (AFTER normalization, BEFORE stringification)
    if flatten_on && input.is_a?(Hash) && input.key?(flatten_on)
      input = input.dup unless normalize_on  # Only dup if not already duped
      input[flatten_on] = Flattener.flatten_array_of_hashes(input[flatten_on])
    end

    # Apply stringification if stringify_on is specified (AFTER normalization and flattening)
    if stringify_on && input.is_a?(Hash) && input.key?(stringify_on)
      input = input.dup unless normalize_on || flatten_on  # Only dup if not already duped
      input[stringify_on] = Stringifier.stringify_array_of_hashes(input[stringify_on])
    end

    normalized_value = Normalizer.normalize_value(input)
    options = resolve_options(indent: indent, delimiter: delimiter, length_marker: length_marker)
    Encoders.encode_value(normalized_value, options)
  end

  # Decode a TOON-formatted string to a Ruby value
  #
  # @param input [String] TOON-formatted string to decode
  # @param indent [Integer] Number of spaces per indentation level (default: 2)
  # @param strict [Boolean] When true, enforce strict validation of array lengths and tabular row counts (default: true)
  # @param destringify_on [String, nil] Optional key name to destringify array of hashes (default: nil)
  # @param unflatten_on [String, nil] Optional key name to unflatten nested hashes in array of hashes (default: nil)
  # @param denormalize_on [String, nil] Optional key name to denormalize array of hashes (default: nil)
  # @return [Object] Decoded Ruby value (Hash, Array, or primitive)
  def decode(input, indent: 2, strict: true, destringify_on: nil, unflatten_on: nil, denormalize_on: nil)
    resolved_options = resolve_decode_options(indent: indent, strict: strict)
    scan_result = Scanner.to_parsed_lines(input, resolved_options[:indent], resolved_options[:strict])

    raise TypeError, 'Cannot decode empty input: input must be a non-empty string' if scan_result.lines.empty?

    cursor = LineCursor.new(scan_result.lines, scan_result.blank_lines)
    result = Decoders.decode_value_from_lines(cursor, resolved_options)

    # Apply destringification if destringify_on is specified (FIRST: inverse of stringify)
    if destringify_on && result.is_a?(Hash) && result.key?(destringify_on)
      result = result.dup
      result[destringify_on] = Destringifier.destringify_array_of_hashes(result[destringify_on])
    end

    # Apply unflattening if unflatten_on is specified (SECOND: inverse of flatten)
    if unflatten_on && result.is_a?(Hash) && result.key?(unflatten_on)
      result = result.dup unless destringify_on
      result[unflatten_on] = Unflattener.unflatten_array_of_hashes(result[unflatten_on])
    end

    # Apply denormalization if denormalize_on is specified (THIRD: inverse of normalize)
    if denormalize_on && result.is_a?(Hash) && result.key?(denormalize_on)
      result = result.dup unless destringify_on || unflatten_on
      result[denormalize_on] = Denormalizer.denormalize_array_of_hashes(result[denormalize_on])
    end

    result
  end

  def resolve_options(indent:, delimiter:, length_marker:)
    {
      indent: indent,
      delimiter: delimiter,
      length_marker: length_marker
    }
  end

  def resolve_decode_options(indent:, strict:)
    {
      indent: indent,
      strict: strict
    }
  end
end
