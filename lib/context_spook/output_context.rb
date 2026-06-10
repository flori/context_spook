# The ContextSpook::OutputContext module provides methods for outputting
# context data in various formats.
#
# This module is included in the ContextSpook::Generator class to enable output
# functionality for generated context objects.
module ContextSpook::OutputContext
  # The output_context_size method prints the total size of the generated
  # context representation and an estimated token count.
  #
  # This method calculates the size of the context object when serialized to
  # JSON (or TOON), formats it using binary units, estimates the token count
  # based on bytes, and outputs the result to standard error.
  def output_context_size
    context          = ''
    if @context
      context        = @format == 'TOON' ? @context.to_toon : @context.to_json
    end
    formatted_size   = ContextSpook::Utils.format_size(context.size)
    tokens           = @token_estimator.call(context)
    formatted_tokens = ContextSpook::Utils.format_tokens(tokens)

    verbose_puts "Built #{formatted_size} (#{formatted_tokens} tokens) of #@format context in total."
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
