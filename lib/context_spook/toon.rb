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
