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
  def self.encode(input, indent: 2, delimiter: DEFAULT_DELIMITER, length_marker: false, normalize_on: nil, flatten_on: nil, stringify_on: nil)
    # Apply transformations recursively at all nesting levels
    input = apply_recursive_transformation(input, normalize_on, :normalize) if normalize_on
    input = apply_recursive_transformation(input, flatten_on, :flatten) if flatten_on
    input = apply_recursive_transformation(input, stringify_on, :stringify) if stringify_on

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
  def self.decode(input, indent: 2, strict: true, destringify_on: nil, unflatten_on: nil, denormalize_on: nil)
    resolved_options = resolve_decode_options(indent: indent, strict: strict)
    scan_result = Scanner.to_parsed_lines(input, resolved_options[:indent], resolved_options[:strict])

    raise TypeError, 'Cannot decode empty input: input must be a non-empty string' if scan_result.lines.empty?

    cursor = LineCursor.new(scan_result.lines, scan_result.blank_lines)
    result = Decoders.decode_value_from_lines(cursor, resolved_options)

    # Apply inverse transformations recursively at all nesting levels (in reverse order)
    result = apply_recursive_transformation(result, destringify_on, :destringify) if destringify_on
    result = apply_recursive_transformation(result, unflatten_on, :unflatten) if unflatten_on
    result = apply_recursive_transformation(result, denormalize_on, :denormalize) if denormalize_on

    result
  end

  class << self
    private

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

    def apply_recursive_transformation(value, target_key, transformation_type)
      case value
      when Hash
        transformed_hash = {}
        value.each do |key, val|
          if key == target_key
            transformed_hash[key] = apply_transformation(val, transformation_type)
          else
            transformed_hash[key] = apply_recursive_transformation(val, target_key, transformation_type)
          end
        end
        transformed_hash
      when Array
        value.map { |item| apply_recursive_transformation(item, target_key, transformation_type) }
      else
        value
      end
    end

    def apply_transformation(value, transformation_type)
      case transformation_type
      when :normalize
        Normalizer.normalize_array_of_hashes(value)
      when :flatten
        Flattener.flatten_array_of_hashes(value)
      when :stringify
        Stringifier.stringify_array_of_hashes(value)
      when :destringify
        Destringifier.destringify_array_of_hashes(value)
      when :unflatten
        Unflattener.unflatten_array_of_hashes(value)
      when :denormalize
        Denormalizer.denormalize_array_of_hashes(value)
      else
        value
      end
    end
  end

  # Mark internal modules and classes as private to hide them from RBI generation
  private_constant :Normalizer
  private_constant :Flattener
  private_constant :Stringifier
  private_constant :Denormalizer
  private_constant :Unflattener
  private_constant :Destringifier
  private_constant :Primitives
  private_constant :Encoders
  private_constant :StringUtils
  private_constant :LiteralUtils
  private_constant :Scanner
  private_constant :Parser
  private_constant :Validation
  private_constant :Decoders
  private_constant :ArrayHeaderInfo
  private_constant :BlankLineInfo
  private_constant :LineCursor
  private_constant :ParsedLine
  private_constant :ScanResult
end
