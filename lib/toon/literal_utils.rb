# frozen_string_literal: true

require_relative 'constants'

module Toon
  module LiteralUtils
    module_function

    # Checks if a token is a boolean or null literal (true, false, null)
    def boolean_or_null_literal?(token)
      token == TRUE_LITERAL || token == FALSE_LITERAL || token == NULL_LITERAL
    end

    # Checks if a token represents a valid numeric literal
    # Rejects numbers with leading zeros (except "0" itself or decimals like "0.5")
    def numeric_literal?(token)
      return false if token.nil? || token.empty?

      # Must not have leading zeros (except for "0" itself or decimals like "0.5")
      return false if token.length > 1 && token[0] == '0' && token[1] != '.'

      # Check if it's a valid number
      num = Float(token) rescue nil
      !num.nil? && num.finite?
    end
  end
end
