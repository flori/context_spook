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
end
