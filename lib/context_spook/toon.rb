require 'ruby_json_toon'

# The ContextSpook::TOON module provides TOON (Token-Oriented Object Notation)
# serialization functionality for context objects.
module ContextSpook::TOON
  # Converts the context object to TOON format.
  #
  # @return [String] the TOON-encoded representation of the context
  def to_toon
    RubyJsonToon.encode(as_json)
  end
  memoize method: :to_toon

  # Calculates the size of the TOON representation.
  #
  # @return [Integer] the size in bytes of the TOON representation
  def toon_size
    to_toon.size
  end
end
