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

  # The toon_example method reads and returns the content of an example
  # Markdown file that demonstrates the TOON (Token-Oriented Object Notation)
  # format.
  #
  # This method is used to provide a sample representation of how context data
  # can be formatted in TOON, which is an alternative serialization format
  # supported by the ContextSpook library.
  #
  # @return [ String ] the content of the TOON example Markdown file
  def toon_example
    File.read(Pathname.new(__dir__) + 'toon/example.md')
  end
end
