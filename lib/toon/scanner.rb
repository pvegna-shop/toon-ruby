# frozen_string_literal: true

require_relative 'constants'

module Toon
  # Represents a parsed line with indentation and content information
  class ParsedLine
    attr_reader :raw, :indent, :content, :depth, :line_number

    def initialize(raw:, indent:, content:, depth:, line_number:)
      @raw = raw
      @indent = indent
      @content = content
      @depth = depth
      @line_number = line_number
    end
  end

  # Represents information about a blank line
  class BlankLineInfo
    attr_reader :line_number, :indent, :depth

    def initialize(line_number:, indent:, depth:)
      @line_number = line_number
      @indent = indent
      @depth = depth
    end
  end

  # Result of scanning a source string
  class ScanResult
    attr_reader :lines, :blank_lines

    def initialize(lines, blank_lines)
      @lines = lines
      @blank_lines = blank_lines
    end
  end

  # Cursor for navigating through parsed lines
  class LineCursor
    attr_reader :blank_lines

    def initialize(lines, blank_lines = [])
      @lines = lines
      @index = 0
      @blank_lines = blank_lines
    end

    def peek
      @lines[@index]
    end

    def next
      line = @lines[@index]
      @index += 1
      line
    end

    def current
      @index > 0 ? @lines[@index - 1] : nil
    end

    def advance
      @index += 1
    end

    def at_end?
      @index >= @lines.length
    end

    def length
      @lines.length
    end

    def peek_at_depth(target_depth)
      line = peek
      return nil if line.nil? || line.depth < target_depth
      return line if line.depth == target_depth
      nil
    end

    def has_more_at_depth?(target_depth)
      !peek_at_depth(target_depth).nil?
    end
  end

  module Scanner
    module_function

    # Parses a TOON source string into parsed lines
    # @param source [String] The TOON source string
    # @param indent_size [Integer] Number of spaces per indentation level
    # @param strict [Boolean] Whether to enforce strict indentation validation
    # @return [ScanResult] The scan result with parsed lines and blank line info
    def to_parsed_lines(source, indent_size, strict)
      return ScanResult.new([], []) if source.strip.empty?

      lines = source.split("\n")
      parsed = []
      blank_lines = []

      lines.each_with_index do |raw, i|
        line_number = i + 1
        indent = 0
        while indent < raw.length && raw[indent] == SPACE
          indent += 1
        end

        content = raw[indent..]

        # Track blank lines
        if content.strip.empty?
          depth = compute_depth_from_indent(indent, indent_size)
          blank_lines << BlankLineInfo.new(line_number: line_number, indent: indent, depth: depth)
          next
        end

        depth = compute_depth_from_indent(indent, indent_size)

        # Strict mode validation
        if strict
          # Find the full leading whitespace region (spaces and tabs)
          ws_end = 0
          while ws_end < raw.length && (raw[ws_end] == SPACE || raw[ws_end] == TAB)
            ws_end += 1
          end

          # Check for tabs in leading whitespace (before actual content)
          if raw[0...ws_end].include?(TAB)
            raise SyntaxError, "Line #{line_number}: Tabs are not allowed in indentation in strict mode"
          end

          # Check for exact multiples of indent_size
          if indent > 0 && indent % indent_size != 0
            raise SyntaxError, "Line #{line_number}: Indentation must be exact multiple of #{indent_size}, but found #{indent} spaces"
          end
        end

        parsed << ParsedLine.new(
          raw: raw,
          indent: indent,
          content: content,
          depth: depth,
          line_number: line_number
        )
      end

      ScanResult.new(parsed, blank_lines)
    end

    def compute_depth_from_indent(indent_spaces, indent_size)
      (indent_spaces / indent_size).floor
    end
  end
end
