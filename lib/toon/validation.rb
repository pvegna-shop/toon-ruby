# frozen_string_literal: true

require_relative 'constants'

module Toon
  module Validation
    module_function

    # Asserts that the actual count matches the expected count in strict mode
    # @param actual [Integer] The actual count
    # @param expected [Integer] The expected count
    # @param item_type [String] The type of items being counted
    # @param strict [Boolean] Whether strict mode is enabled
    # @raise [RangeError] if counts don't match in strict mode
    def assert_expected_count(actual, expected, item_type, strict)
      return unless strict
      return if actual == expected

      raise RangeError, "Expected #{expected} #{item_type}, but got #{actual}"
    end

    # Validates that there are no extra list items beyond the expected count
    # @param cursor [LineCursor] The line cursor
    # @param item_depth [Integer] The expected depth of items
    # @param expected_count [Integer] The expected number of items
    # @raise [RangeError] if extra items are found
    def validate_no_extra_list_items(cursor, item_depth, expected_count)
      return if cursor.at_end?

      next_line = cursor.peek
      if next_line && next_line.depth == item_depth && next_line.content.start_with?(LIST_ITEM_PREFIX)
        raise RangeError, "Expected #{expected_count} list array items, but found more"
      end
    end

    # Validates that there are no extra tabular rows beyond the expected count
    # @param cursor [LineCursor] The line cursor
    # @param row_depth [Integer] The expected depth of rows
    # @param header [ArrayHeaderInfo] The array header info containing length and delimiter
    # @raise [RangeError] if extra rows are found
    def validate_no_extra_tabular_rows(cursor, row_depth, header)
      return if cursor.at_end?

      next_line = cursor.peek
      if next_line &&
         next_line.depth == row_depth &&
         !next_line.content.start_with?(LIST_ITEM_PREFIX) &&
         data_row?(next_line.content, header.delimiter)
        raise RangeError, "Expected #{header.length} tabular rows, but found more"
      end
    end

    # Validates that there are no blank lines within a specific line range
    # In strict mode, blank lines inside arrays/tabular rows are not allowed
    # @param start_line [Integer] The starting line number (inclusive)
    # @param end_line [Integer] The ending line number (inclusive)
    # @param blank_lines [Array<BlankLineInfo>] Array of blank line information
    # @param strict [Boolean] Whether strict mode is enabled
    # @param context [String] Description of the context (e.g., "list array", "tabular array")
    # @raise [SyntaxError] if blank lines are found in strict mode
    def validate_no_blank_lines_in_range(start_line, end_line, blank_lines, strict, context)
      return unless strict

      # Find blank lines within the range
      # Note: We don't filter by depth because ANY blank line between array items is an error,
      # regardless of its indentation level
      blanks_in_range = blank_lines.select do |blank|
        blank.line_number > start_line && blank.line_number < end_line
      end

      return if blanks_in_range.empty?

      raise SyntaxError, "Line #{blanks_in_range[0].line_number}: Blank lines inside #{context} are not allowed in strict mode"
    end

    # Checks if a line represents a data row (as opposed to a key-value pair) in a tabular array
    # @param content [String] The line content
    # @param delimiter [String] The delimiter used in the table
    # @return [Boolean] true if the line is a data row, false if it's a key-value pair
    def data_row?(content, delimiter)
      colon_pos = content.index(COLON)
      delimiter_pos = content.index(delimiter)

      # No colon = definitely a data row
      return true if colon_pos.nil?

      # Has delimiter and it comes before colon = data row
      return true if delimiter_pos && delimiter_pos < colon_pos

      # Colon before delimiter or no delimiter = key-value pair
      false
    end
  end
end
