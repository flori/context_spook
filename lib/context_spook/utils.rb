# The ContextSpook::Utils module provides utility methods for formatting and
# processing context data.
module ContextSpook::Utils
  module_function

  # The format_size method converts a byte size value into a human-readable
  # string with binary units.
  #
  # library to display the size with appropriate IEC prefixes (KiB, MiB,
  # etc.) and one decimal place.
  #
  # @param context_size [ Integer ] the size in bytes to be formatted
  #
  # @return [ String ] the formatted size string with binary units
  def format_size(context_size)
    Tins::Unit.format(context_size, format: '%.1f %U', unit: ?B, prefix: :iec_uc)
  end

  # The format_tokens method converts a token count into a human-readable
  # string using SI prefixes (e.g., 1.2 kT).
  #
  # @param tokens [ Integer ] the number of tokens to be formatted
  #
  # @return [ String ] the formatted token string
  def format_tokens(tokens)
    Tins::Unit.format(tokens, unit: ?T, prefix: :si_uc, format: '%.1f %U')
  end

  # The estimate_tokens method provides a crude estimation of token counts
  # from either a raw byte count or a string.
  #
  # This follows a heuristic where one token is roughly equivalent to 3.5
  # bytes. A numeric argument is treated as a byte count directly; any other
  # value is converted to a string and measured by its byte size.
  #
  # @param text_or_bytesize [ String, Integer ] the content to estimate
  #   tokens for, either as a string or a precomputed byte count
  #
  # @return [ Integer ] the estimated number of tokens
  def estimate_tokens(text_or_bytesize)
    unless text_or_bytesize.is_a?(Numeric)
      text_or_bytesize = text_or_bytesize.to_s.bytesize
    end
    (text_or_bytesize.to_f / 3.5).ceil
  end
end
