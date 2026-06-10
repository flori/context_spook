# The ContextSpook::Utils module provides utility methods for formatting and
# processing context data.
module ContextSpook::Utils
  module_function

  # The format_size method converts a byte size value into a human-readable
  # string with binary units.
  #
  # This method takes a raw byte count and formats it using the Tins::Unit
  # library to display the size with appropriate binary prefixes (KiB, MiB,
  # etc.) and two decimal places.
  #
  # @param context_size [ Integer ] the size in bytes to be formatted
  #
  # @return [ String ] the formatted size string with binary units
  def format_size(context_size)
    Tins::Unit.format(context_size, format: '%.2f %U', unit: ?b, prefix: 1024)
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
  # based on the byte size of the input content.
  #
  # This follows a heuristic where one token is roughly equivalent to 3.5 bytes.
  #
  # @param text [ String ] the content to be estimated
  #
  # @return [ Integer ] the estimated number of tokens
  def estimate_tokens(text)
    (text.size.to_f / 3.5).ceil
  end
end
