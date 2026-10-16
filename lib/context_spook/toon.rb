require 'json'
require 'context_spook/toon/encoder'

# The ContextSpook::TOON module provides TOON (Token-Oriented Object Notation)
# v4 serialization functionality for context objects.
module ContextSpook::TOON
  # Converts the context object to TOON v4 format.
  #
  # Uses a fast JSON round-trip (C-optimized) to normalize the data,
  # then walks the canonical Hash/Array tree with our native encoder.
  #
  # @return [String] the TOON-encoded representation of the context
  def to_toon
    Encoder.encode(as_json)
  end
  memoize method: :to_toon

  # Calculates the size of the TOON representation.
  #
  # @return [Integer] the size in bytes of the TOON representation
  def toon_size
    to_toon.bytesize
  end

  # Streams the TOON v4 output to the given IO.
  #
  # @param output [IO] the IO to write to (e.g. STDOUT, File, StringIO)
  def to_toon_stream(output)
    Encoder.encode(as_json, output: output)
  end
end
