# frozen_string_literal: true

require_relative 'constants'
require_relative 'scanner'
require_relative 'parser'
require_relative 'validation'
require_relative 'string_utils'

module Toon
  module Decoders
    module_function

    # Entry decoding

    # Decodes a value from a cursor of parsed lines
    def decode_value_from_lines(cursor, options)
      first = cursor.peek
      raise ReferenceError, 'No content to decode' if first.nil?

      # Check for root array
      if Parser.array_header_after_hyphen?(first.content)
        header_info = Parser.parse_array_header_line(first.content, DEFAULT_DELIMITER)
        if header_info
          cursor.advance # Move past the header line
          return decode_array_from_header(
            header_info[:header],
            header_info[:inline_values],
            cursor,
            0,
            options
          )
        end
      end

      # Check for single primitive value
      if cursor.length == 1 && !key_value_line?(first)
        return Parser.parse_primitive_token(first.content.strip)
      end

      # Default to object
      decode_object(cursor, 0, options)
    end

    # Checks if a line is a key-value line
    def key_value_line?(line)
      content = line.content
      # Look for unquoted colon or quoted key followed by colon
      if content.start_with?(DOUBLE_QUOTE)
        # Quoted key - find the closing quote
        closing_quote_index = StringUtils.find_closing_quote(content, 0)
        return false if closing_quote_index.nil?

        # Check if there's a colon after the quoted key
        return closing_quote_index + 1 < content.length && content[closing_quote_index + 1] == COLON
      else
        # Unquoted key - look for first colon not inside quotes
        return content.include?(COLON)
      end
    end

    # Object decoding

    def decode_object(cursor, base_depth, options)
      obj = {}

      until cursor.at_end?
        line = cursor.peek
        break if line.nil? || line.depth < base_depth
        break if line.depth != base_depth

        key, value = decode_key_value_pair(line, cursor, base_depth, options)
        obj[key] = value
      end

      obj
    end

    def decode_key_value(content, cursor, base_depth, options)
      # Check for array header first (before parsing key)
      array_header = Parser.parse_array_header_line(content, DEFAULT_DELIMITER)
      if array_header && array_header[:header].key
        value = decode_array_from_header(
          array_header[:header],
          array_header[:inline_values],
          cursor,
          base_depth,
          options
        )
        # After an array, subsequent fields are at base_depth + 1 (where array content is)
        return {
          key: array_header[:header].key,
          value: value,
          follow_depth: base_depth + 1
        }
      end

      # Regular key-value pair
      parsed = Parser.parse_key_token(content, 0)
      key = parsed[:key]
      rest = content[parsed[:end]..].strip

      # No value after colon - expect nested object or empty
      if rest.empty?
        next_line = cursor.peek
        if next_line && next_line.depth > base_depth
          nested = decode_object(cursor, base_depth + 1, options)
          return { key: key, value: nested, follow_depth: base_depth + 1 }
        end
        # Empty object
        return { key: key, value: {}, follow_depth: base_depth + 1 }
      end

      # Inline primitive value
      value = Parser.parse_primitive_token(rest)
      { key: key, value: value, follow_depth: base_depth + 1 }
    end

    def decode_key_value_pair(line, cursor, base_depth, options)
      cursor.advance
      result = decode_key_value(line.content, cursor, base_depth, options)
      [result[:key], result[:value]]
    end

    # Array decoding

    def decode_array_from_header(header, inline_values, cursor, base_depth, options)
      # Inline primitive array
      if inline_values
        return decode_inline_primitive_array(header, inline_values, options)
      end

      # Tabular array
      if header.fields && header.fields.length > 0
        return decode_tabular_array(header, cursor, base_depth, options)
      end

      # List array
      decode_list_array(header, cursor, base_depth, options)
    end

    def decode_inline_primitive_array(header, inline_values, options)
      if inline_values.strip.empty?
        Validation.assert_expected_count(0, header.length, 'inline array items', options[:strict])
        return []
      end

      values = Parser.parse_delimited_values(inline_values, header.delimiter)
      primitives = Parser.map_row_values_to_primitives(values)

      Validation.assert_expected_count(primitives.length, header.length, 'inline array items', options[:strict])

      primitives
    end

    def decode_list_array(header, cursor, base_depth, options)
      items = []
      item_depth = base_depth + 1

      # Track line range for blank line validation
      start_line = nil
      end_line = nil

      while !cursor.at_end? && items.length < header.length
        line = cursor.peek
        break if line.nil? || line.depth < item_depth

        if line.depth == item_depth && line.content.start_with?(LIST_ITEM_PREFIX)
          # Track first and last item line numbers
          start_line = line.line_number if start_line.nil?
          end_line = line.line_number

          item = decode_list_item(cursor, item_depth, header.delimiter, options)
          items << item

          # Update end_line to the current cursor position (after item was decoded)
          current_line = cursor.current
          end_line = current_line.line_number if current_line
        else
          break
        end
      end

      Validation.assert_expected_count(items.length, header.length, 'list array items', options[:strict])

      # In strict mode, check for blank lines inside the array
      if options[:strict] && start_line && end_line
        Validation.validate_no_blank_lines_in_range(
          start_line,
          end_line,
          cursor.blank_lines,
          options[:strict],
          'list array'
        )
      end

      # In strict mode, check for extra items
      if options[:strict]
        Validation.validate_no_extra_list_items(cursor, item_depth, header.length)
      end

      items
    end

    def decode_tabular_array(header, cursor, base_depth, options)
      objects = []
      row_depth = base_depth + 1

      # Track line range for blank line validation
      start_line = nil
      end_line = nil

      while !cursor.at_end? && objects.length < header.length
        line = cursor.peek
        break if line.nil? || line.depth < row_depth

        if line.depth == row_depth
          # Track first and last row line numbers
          start_line = line.line_number if start_line.nil?
          end_line = line.line_number

          cursor.advance
          values = Parser.parse_delimited_values(line.content, header.delimiter)
          Validation.assert_expected_count(values.length, header.fields.length, 'tabular row values', options[:strict])

          primitives = Parser.map_row_values_to_primitives(values)
          obj = {}

          header.fields.each_with_index do |field, i|
            obj[field] = primitives[i]
          end

          objects << obj
        else
          break
        end
      end

      Validation.assert_expected_count(objects.length, header.length, 'tabular rows', options[:strict])

      # In strict mode, check for blank lines inside the array
      if options[:strict] && start_line && end_line
        Validation.validate_no_blank_lines_in_range(
          start_line,
          end_line,
          cursor.blank_lines,
          options[:strict],
          'tabular array'
        )
      end

      # In strict mode, check for extra rows
      if options[:strict]
        Validation.validate_no_extra_tabular_rows(cursor, row_depth, header)
      end

      objects
    end

    # List item decoding

    def decode_list_item(cursor, base_depth, active_delimiter, options)
      line = cursor.next
      raise ReferenceError, 'Expected list item' if line.nil?

      after_hyphen = line.content[LIST_ITEM_PREFIX.length..]

      # Check for array header after hyphen
      if Parser.array_header_after_hyphen?(after_hyphen)
        array_header = Parser.parse_array_header_line(after_hyphen, DEFAULT_DELIMITER)
        if array_header
          return decode_array_from_header(
            array_header[:header],
            array_header[:inline_values],
            cursor,
            base_depth,
            options
          )
        end
      end

      # Check for object first field after hyphen
      if Parser.object_first_field_after_hyphen?(after_hyphen)
        return decode_object_from_list_item(line, cursor, base_depth, options)
      end

      # Primitive value
      Parser.parse_primitive_token(after_hyphen)
    end

    def decode_object_from_list_item(first_line, cursor, base_depth, options)
      after_hyphen = first_line.content[LIST_ITEM_PREFIX.length..]
      result = decode_key_value(after_hyphen, cursor, base_depth, options)

      obj = { result[:key] => result[:value] }
      follow_depth = result[:follow_depth]

      # Read subsequent fields
      until cursor.at_end?
        line = cursor.peek
        break if line.nil? || line.depth < follow_depth
        break if line.depth != follow_depth || line.content.start_with?(LIST_ITEM_PREFIX)

        k, v = decode_key_value_pair(line, cursor, follow_depth, options)
        obj[k] = v
      end

      obj
    end
  end
end
