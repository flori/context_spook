# The ContextSpook::OutputContext module provides methods for outputting
# context data in various formats.
#
# This module is included in the ContextSpook::Generator class to enable output
# functionality for generated context objects.
module ContextSpook::OutputContext
  # The output_context_size method prints the total size of the generated
  # context JSON representation.
  #
  # This method calculates the size of the context object when serialized to
  # JSON, formats it using binary units (KiB, MiB, etc.), and outputs the
  # result to standard error.
  def output_context_size
    context_size =
      (@format == 'TOON' ? @context&.toon_size : @context&.size).to_i
    context_size = ContextSpook::Utils.format_size(context_size)
    verbose_puts "Built #{context_size} of #@format context in total."
  end

  # The output_context method writes the generated context to the specified
  # output stream in either TOON or JSON format.
  #
  # This method serializes the context object into either TOON format or JSON
  # format depending on the configured format, and writes the result to the
  # provided output stream, which defaults to STDOUT.
  #
  # @param output [ IO ] the output stream to write the context data to,
  #   defaults to STDOUT
  def output_context(output: STDOUT)
    if @format == 'TOON'
      output.puts(@context.to_toon)
    else
      JSON.dump(@context.as_json, output)
    end
  end
end
