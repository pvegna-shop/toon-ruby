# frozen_string_literal: true

require_relative 'constants'

module Toon
  module StringUtils
    module_function

    # Escapes special characters in a string for encoding
    # Handles backslashes, quotes, newlines, carriage returns, and tabs
    def escape_string(value)
      value
        .gsub(BACKSLASH, "#{BACKSLASH}#{BACKSLASH}")
        .gsub(DOUBLE_QUOTE, "#{BACKSLASH}#{DOUBLE_QUOTE}")
        .gsub("\n", "#{BACKSLASH}n")
        .gsub("\r", "#{BACKSLASH}r")
        .gsub("\t", "#{BACKSLASH}t")
    end

    # Unescapes a string by processing escape sequences
    # Handles \n, \t, \r, \\, and \" escape sequences
    def unescape_string(value)
      result = ''
      i = 0

      while i < value.length
        if value[i] == BACKSLASH
          raise SyntaxError, 'Invalid escape sequence: backslash at end of string' if i + 1 >= value.length

          next_char = value[i + 1]
          case next_char
          when 'n'
            result += NEWLINE
            i += 2
          when 't'
            result += TAB
            i += 2
          when 'r'
            result += CARRIAGE_RETURN
            i += 2
          when BACKSLASH
            result += BACKSLASH
            i += 2
          when DOUBLE_QUOTE
            result += DOUBLE_QUOTE
            i += 2
          else
            raise SyntaxError, "Invalid escape sequence: \\#{next_char}"
          end
        else
          result += value[i]
          i += 1
        end
      end

      result
    end

    # Finds the index of the closing double quote in a string, accounting for escape sequences
    # @param content [String] The string to search in
    # @param start [Integer] The index of the opening quote
    # @return [Integer, nil] The index of the closing quote, or nil if not found
    def find_closing_quote(content, start)
      i = start + 1
      while i < content.length
        if content[i] == BACKSLASH && i + 1 < content.length
          # Skip escaped character
          i += 2
          next
        end
        return i if content[i] == DOUBLE_QUOTE

        i += 1
      end
      nil # Not found
    end

    # Finds the index of a specific character outside of quoted sections
    # @param content [String] The string to search in
    # @param char [String] The character to look for
    # @param start [Integer] Optional starting index (defaults to 0)
    # @return [Integer, nil] The index of the character, or nil if not found outside quotes
    def find_unquoted_char(content, char, start = 0)
      in_quotes = false
      i = start

      while i < content.length
        if content[i] == BACKSLASH && i + 1 < content.length && in_quotes
          # Skip escaped character
          i += 2
          next
        end

        if content[i] == DOUBLE_QUOTE
          in_quotes = !in_quotes
          i += 1
          next
        end

        return i if content[i] == char && !in_quotes

        i += 1
      end

      nil
    end
  end
end
