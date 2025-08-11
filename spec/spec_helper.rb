require 'gem_hadar/simplecov'
GemHadar::SimpleCov.start
require 'rspec'
require 'tins/xt/expose'
begin
  require 'debug'
rescue LoadError
end
require 'context_spook'

# The asset method constructs a file path by joining the directory of the
# current file, an 'assets' subdirectory, and the provided filename.
#
# @param name [ String ] the name of the asset file to be located
#
# @return [ String ] the complete file path to the asset
def asset(name)
  File.join(__dir__, 'assets', name)
end
