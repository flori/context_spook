require 'ruby_json_toon'

module ContextSpook::TOON
  def to_toon
    RubyJsonToon.encode(as_json)
  end
  memoize method: :to_toon

  def toon_size
    to_toon.size
  end
end
