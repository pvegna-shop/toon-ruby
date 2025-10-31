# frozen_string_literal: true

require_relative 'constants'
require_relative 'string_utils'
require_relative 'literal_utils'

module Toon
  # Information about an array header
  class ArrayHeaderInfo
    attr_reader :key, :length, :delimiter, :fields, :has_length_marker

    def initialize(key:, length:, delimiter:, fields:, has_length_marker:)
      @key = key
      @length = length
      @delimiter = delimiter
      @fields = fields
      @has_length_marker = has_length_marker
    end
  end

  module Parser
    module_function

    # Array header parsing

    # Parses an array header line (e.g., "key[N]: values" or "key[N]{fields}:")
    # @param content [String] The line content to parse
    # @param default_delimiter [String] The default delimiter to use
    # @return [Hash, nil] Hash with :header and optional :inline_values, or nil if not an array header
    def parse_array_header_line(content, default_delimiter)
      # Don't match if the line starts with a quote (it's a quoted key, not an array)
      return nil if content.strip.start_with?(DOUBLE_QUOTE)

      # Find the bracket segment first
      bracket_start = content.index(OPEN_BRACKET)
      return nil if bracket_start.nil?

      bracket_end = content.index(CLOSE_BRACKET, bracket_start)
      return nil if bracket_end.nil?

      # Find the colon that comes after all brackets and braces
      colon_index = bracket_end + 1
      brace_end = colon_index

      # Check for fields segment (braces come after bracket)
      brace_start = content.index(OPEN_BRACE, bracket_end)
      if brace_start && brace_start < content.index(COLON, bracket_end).to_i
        found_brace_end = content.index(CLOSE_BRACE, brace_start)
        brace_end = found_brace_end + 1 if found_brace_end
      end

      # Now find colon after brackets and braces
      colon_index = content.index(COLON, [bracket_end, brace_end].max)
      return nil if colon_index.nil?

      key = bracket_start > 0 ? content[0...bracket_start] : nil
      after_colon = content[(colon_index + 1)..].strip

      bracket_content = content[(bracket_start + 1)...bracket_end]

      # Try to parse bracket segment
      begin
        parsed_bracket = parse_bracket_segment(bracket_content, default_delimiter)
      rescue
        return nil
      end

      length = parsed_bracket[:length]
      delimiter = parsed_bracket[:delimiter]
      has_length_marker = parsed_bracket[:has_length_marker]

      # Check for fields segment
      fields = nil
      if brace_start && brace_start < colon_index
        found_brace_end = content.index(CLOSE_BRACE, brace_start)
        if found_brace_end && found_brace_end < colon_index
          fields_content = content[(brace_start + 1)...found_brace_end]
          fields = parse_delimited_values(fields_content, delimiter).map { |field| parse_string_literal(field.strip) }
        end
      end

      {
        header: ArrayHeaderInfo.new(
          key: key,
          length: length,
          delimiter: delimiter,
          fields: fields,
          has_length_marker: has_length_marker
        ),
        inline_values: after_colon.empty? ? nil : after_colon
      }
    end

    # Parses the bracket segment of an array header (e.g., "N", "#N", "N|", "#N\t")
    def parse_bracket_segment(seg, default_delimiter)
      has_length_marker = false
      content = seg

      # Check for length marker
      if content.start_with?(HASH)
        has_length_marker = true
        content = content[1..]
      end

      # Check for delimiter suffix
      delimiter = default_delimiter
      if content.end_with?(TAB)
        delimiter = TAB
        content = content[0...-1]
      elsif content.end_with?(PIPE)
        delimiter = PIPE
        content = content[0...-1]
      end

      length = content.to_i
      raise TypeError, "Invalid array length: #{seg}" if length == 0 && content != '0'

      {
        length: length,
        delimiter: delimiter,
        has_length_marker: has_length_marker
      }
    end

    # Delimited value parsing

    # Parses delimited values, respecting quoted strings
    def parse_delimited_values(input, delimiter)
      values = []
      current = ''
      in_quotes = false
      i = 0

      while i < input.length
        char = input[i]

        if char == BACKSLASH && i + 1 < input.length && in_quotes
          # Escape sequence in quoted string
          current += char + input[i + 1]
          i += 2
          next
        end

        if char == DOUBLE_QUOTE
          in_quotes = !in_quotes
          current += char
          i += 1
          next
        end

        if char == delimiter && !in_quotes
          values << current.strip
          current = ''
          i += 1
          next
        end

        current += char
        i += 1
      end

      # Add last value
      values << current.strip if !current.empty? || values.length > 0

      values
    end

    # Maps row values to primitives
    def map_row_values_to_primitives(values)
      values.map { |v| parse_primitive_token(v) }
    end

    # Primitive and key parsing

    # Parses a primitive token (string, number, boolean, null)
    def parse_primitive_token(token)
      trimmed = token.strip

      # Empty token
      return '' if trimmed.empty?

      # Quoted string (if starts with quote, it MUST be properly quoted)
      return parse_string_literal(trimmed) if trimmed.start_with?(DOUBLE_QUOTE)

      # Boolean or null literals
      if LiteralUtils.boolean_or_null_literal?(trimmed)
        return true if trimmed == TRUE_LITERAL
        return false if trimmed == FALSE_LITERAL
        return nil if trimmed == NULL_LITERAL
      end

      # Numeric literal
      if LiteralUtils.numeric_literal?(trimmed)
        # Parse as integer if it doesn't have decimal point or exponent
        return trimmed.include?('.') || trimmed.downcase.include?('e') ? trimmed.to_f : trimmed.to_i
      end

      # Unquoted string
      trimmed
    end

    # Parses a string literal, handling quotes and escape sequences
    def parse_string_literal(token)
      trimmed = token.strip

      if trimmed.start_with?(DOUBLE_QUOTE)
        # Find the closing quote, accounting for escaped quotes
        closing_quote_index = StringUtils.find_closing_quote(trimmed, 0)

        raise SyntaxError, 'Unterminated string: missing closing quote' if closing_quote_index.nil?

        if closing_quote_index != trimmed.length - 1
          raise SyntaxError, 'Unexpected characters after closing quote'
        end

        content = trimmed[1...closing_quote_index]
        return StringUtils.unescape_string(content)
      end

      trimmed
    end

    # Parses an unquoted key (stops at colon)
    def parse_unquoted_key(content, start)
      end_pos = start
      end_pos += 1 while end_pos < content.length && content[end_pos] != COLON

      # Validate that a colon was found
      raise SyntaxError, 'Missing colon after key' if end_pos >= content.length || content[end_pos] != COLON

      key = content[start...end_pos].strip

      # Skip the colon
      end_pos += 1

      { key: key, end: end_pos }
    end

    # Parses a quoted key (stops at closing quote + colon)
    def parse_quoted_key(content, start)
      # Find the closing quote, accounting for escaped quotes
      closing_quote_index = StringUtils.find_closing_quote(content, start)

      raise SyntaxError, 'Unterminated quoted key' if closing_quote_index.nil?

      # Extract and unescape the key content
      key_content = content[(start + 1)...closing_quote_index]
      key = StringUtils.unescape_string(key_content)
      end_pos = closing_quote_index + 1

      # Validate and skip colon after quoted key
      raise SyntaxError, 'Missing colon after key' if end_pos >= content.length || content[end_pos] != COLON

      end_pos += 1

      { key: key, end: end_pos }
    end

    # Parses a key token (quoted or unquoted)
    def parse_key_token(content, start)
      if content[start] == DOUBLE_QUOTE
        parse_quoted_key(content, start)
      else
        parse_unquoted_key(content, start)
      end
    end

    # Array content detection helpers

    # Checks if content is an array header after a hyphen
    def array_header_after_hyphen?(content)
      content.strip.start_with?(OPEN_BRACKET) && !StringUtils.find_unquoted_char(content, COLON).nil?
    end

    # Checks if content is an object's first field after a hyphen
    def object_first_field_after_hyphen?(content)
      !StringUtils.find_unquoted_char(content, COLON).nil?
    end
  end
end
