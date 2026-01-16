module ContextSpook
  # The VerbosePuts module provides a conditional output mechanism for
  # displaying status or debug messages.
  #
  # This module includes a method that outputs messages to standard error only
  # when a verbose flag is enabled. It is designed to be included in classes
  # that need to conditionally emit verbose logging information during
  # processing.
  module VerbosePuts
    # The verbose_puts method outputs the given arguments to standard error
    # only if verbose mode is enabled.
    #
    # This method serves as a conditional output mechanism, allowing debug or
    # status messages to be displayed based on the verbosity setting of the
    # object.
    #
    # @param a [ Array ] the arguments to be printed to standard error
    #
    # @return [ nil ] always returns nil after attempting to output
    def verbose_puts(*a)
      verbose or return
      STDERR.puts(a)
    end
  end
end
