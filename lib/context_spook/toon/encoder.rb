# frozen_string_literal: true

require 'json'
require 'stringio'
require 'bigdecimal'

module ContextSpook::TOON
end

# The ContextSpook::TOON::Encoder class encodes Ruby data structures into
# TOON (Token-Oriented Object Notation) v4.4 format. It is fully conformant
# to the v4.4 encode fixtures from the toon-format-spec repository.
#
# It supports:
# - Tabular arrays with nested field groups (v4.0)
# - Keyed tabular form (v4.0)
# - Strict JSON number grammar, shortest round-trip floats (v4.2)
# - Delimiter-aware quoting, C0 escaping, BOM handling (v4.2)
# - Structural-char/combining-mark quoting (v4.4)
# - Streaming output via the +output:+ keyword argument
#
# @example Encoding to a string
#   result = ContextSpook::TOON::Encoder.encode({ 'foo' => 'bar' })
#   # => "foo: bar"
#
# @example Streaming to an IO
#   io = StringIO.new
#   ContextSpook::TOON::Encoder.encode({ 'foo' => 'bar' }, output: io)
#   io.string
#   # => "foo: bar"
class ContextSpook::TOON::Encoder
  JSON_NUMBER = /\A-?(?:0|[1-9]\d*)(?:\.\d+)?(?:[eE][+-]?\d+)?\z/
  private_constant :JSON_NUMBER
  SAFE_KEY    = /\A[a-zA-Z_][a-zA-Z0-9_.]*\z/
  private_constant :SAFE_KEY

  attr_reader :indent_size, :delimiter

  # A private Array subclass that accumulates output lines and provides a
  # +string+ method to join them with newlines, serving as the internal
  # buffer when no external IO is specified for streaming output.
  class StringArray < Array
    # Joins all accumulated lines in the array into a single string,
    # separating each line with a newline character.
    #
    # This method provides the final string representation of the internally
    # accumulated output, serving as the terminal step in the encoding
    # pipeline when no external IO stream is provided.
    #
    # @return [ String ] the fully joined string representation of the
    #   accumulated array elements
    def string
      self * ?\n
    end
  end
  private_constant :StringArray

  # Creates a new encoder.
  #
  # @param indent [Integer] number of spaces per indent level
  # @param delimiter [String] the field/cell separator (default ",")
  # @param output [IO, nil] an IO to stream lines to, or +nil+ to
  #   accumulate internally
  def initialize(indent: 2, delimiter: ',', output: nil)
    @indent_size = indent
    @delimiter   = delimiter
    @output      = output || StringArray.new
    @started     = false if output
  end

  # Encodes +data+ into a TOON v4.4 document string (or streams it to an
  # IO when +output:+ is given).
  #
  # @param data [Object] the Ruby data structure to encode
  # @param indent [Integer] number of spaces per indent level
  # @param delimiter [String] the field/cell separator (default ",")
  # @param output [IO, nil] an IO to stream lines to, or +nil+ to
  #   accumulate and return the string
  # @return [String, nil] the encoded document, or +nil+ when streaming
  def self.encode(data, indent: 2, delimiter: ',', output: nil)
    encoder = new(indent:, delimiter:, output:)
    encoder.encode(data, 0)
    encoder.to_s unless output
  end

  # Encodes +value+ (Hash, Array, or scalar) at the given depth. This is
  # the internal entry point used by {self.encode}.
  #
  # @param value [Object] the data to encode
  # @param depth [Integer] the indent depth
  def encode(value, depth)
    case value
    when Hash  then encode_hash(value, depth)
    when Array then encode_array(value, depth)
    else            push(depth, encode_scalar(value))
    end
  end

  # Returns the accumulated TOON output as a single string.
  #
  # @return [String] the full encoded document
  def to_s
    @output.string
  end

  private

  # Writes one output line at the given indent depth, managing line separation.
  #
  # This method appends a line to the internal output buffer, prefixing it with
  # indentation based on the provided depth and indent size. It handles the
  # state of the buffer to ensure newlines are correctly inserted between
  # lines, except after the very first line which starts the buffer.
  #
  # @param depth [ Integer ] the indent depth level, used to calculate the
  #   number of indentation spaces
  # @param content [ String ] the content of the line to be written, without
  #   indentation or trailing newlines
  #
  # @return [ ContextSpook::TOON::Encoder ] returns self to allow for method chaining
  def push(depth, content)
    if @started.nil?
      @output << (' ' * (depth * @indent_size)).concat(content)
    elsif @started == true
      @output << (+?\n).concat(' ' * (depth * @indent_size)).concat(content)
    else
      @output << (' ' * (depth * @indent_size)).concat(content)
      @started = true
    end
    self
  end

  # Builds a TOON length header such as +[3]+ or +[2:]+. When the active
  # delimiter is not the default comma it is echoed inside the brackets
  # (e.g. +[3|]+) to signal the separator in use.
  #
  # @param n [Integer] the element count
  # @param keyed [Boolean] whether this is a keyed (map) header
  # @return [String] the length header
  def length_header(n, keyed: false)
    d = @delimiter == ',' ? '' : @delimiter
    keyed ? "[#{n}:#{d}]" : "[#{n}#{d}]"
  end

  # Encodes a Hash, using keyed tabular form when eligible and otherwise
  # emitting each field in turn.
  #
  # @param hash [Hash] the hash to encode
  # @param depth [Integer] the indent depth
  def encode_hash(hash, depth)
    if keyed_tabular?(hash)
      encode_keyed_tabular(hash, depth)
    else
      hash.each { |key, value| encode_hash_pair(key, value, depth) }
    end
  end

  # Encodes a single +key: value+ pair of a non-keyed hash, dispatching
  # the value to Hash, Array, or scalar encoding as appropriate.
  #
  # @param key [Object] the field name
  # @param value [Object] the field value
  # @param depth [Integer] the indent depth of the pair
  def encode_hash_pair(key, value, depth)
    k = encode_key(key)

    case value
    when Hash
      if value.empty?
        push(depth, "#{k}:")
      elsif keyed_tabular?(value)
        encode_keyed_tabular(value, depth, key: k)
      else
        push(depth, "#{k}:")
        encode_hash(value, depth + 1)
      end

    when Array
      if value.empty?
        push(depth, "#{k}: []")
      elsif tabular_array?(value)
        encode_tabular(k, value, depth)
      elsif primitive_array?(value)
        push(depth, "#{k}#{length_header(value.size)}: " \
               "#{value.map { |v| encode_scalar(v) }.join(@delimiter)}")
      else
        encode_list(k, value, depth)
      end
    else
      push(depth, "#{k}: #{encode_scalar(value)}")
    end
  end

  # Encodes a root-level array, dispatching to empty, tabular, inline
  # scalar, or list form based on the array's contents.
  #
  # @param array [Array] the array to encode
  # @param depth [Integer] the indent depth
  def encode_array(array, depth)
    if array.empty?
      push(depth, '[]')
      return
    end

    if tabular_array?(array)
      encode_tabular(nil, array, depth)
    elsif primitive_array?(array)
      line = array.map { |v| encode_scalar(v) }.join(@delimiter)
      push(depth, "#{length_header(array.size)}: #{line}")
    else
      encode_list(nil, array, depth)
    end
  end

  # Encodes a non-tabular array in list form: a +[n]:+ header line
  # followed by one list item per element.
  #
  # @param key [String, nil] an optional field name prefix on the header
  # @param array [Array] the elements to encode
  # @param depth [Integer] the indent depth of the header
  def encode_list(key, array, depth)
    label = key ? "#{key}#{length_header(array.size)}:" : \
                        "#{length_header(array.size)}:"
    push(depth, label)
    array.each { |item| encode_list_item(item, depth + 1) }
  end

  # Encodes a single list item, dispatching on its type: Hashes expand
  # into a field block, Arrays into a nested list, scalars into a plain
  # bullet value.
  #
  # @param item [Object] the list item
  # @param depth [Integer] the indent depth of the bullet line
  def encode_list_item(item, depth)
    case item
    when Hash
      if item.empty?
        push(depth, '-')
      else
        encode_list_hash(item, depth)
      end
    when Array
      encode_list_array(item, depth)
    else
      push(depth, "- #{encode_scalar(item)}")
    end
  end

  # Encodes a Hash that is a list item: the first field is emitted on the
  # bullet line and the remaining fields follow at the sibling indent.
  #
  # @param hash [Hash] the list-item hash
  # @param depth [Integer] the indent depth of the bullet line
  def encode_list_hash(hash, depth)
    first = true
    hash.each do |k, v|
      if first
        push_list_field(k, v, depth, hyphen: true)
        first = false
      else
        push_list_field(k, v, depth + 1, hyphen: false)
      end
    end
  end

  # Encodes one field of a list item. The +hyphen:+ flag controls whether
  # the field sits on the "- " bullet line and whether its nested content
  # is indented one extra level to clear the bullet.
  #
  # @param key [Object] the field name
  # @param value [Object] the field value
  # @param depth [Integer] the indent depth of the field line
  # @param hyphen [Boolean] whether this field is on the bullet line
  def push_list_field(key, value, depth, hyphen:)
    k = encode_key(key)
    prefix = hyphen ? '- ' : ''
    # Nested content under a hyphen line gets one extra indent level
    # because "- " occupies one indent step.
    child_depth = hyphen ? depth + 2 : depth + 1

    case value
    when Hash
      if value.empty?
        push(depth, "#{prefix}#{k}:")
      elsif keyed_tabular?(value)
        rd = hyphen ? depth + 2 : depth + 1
        encode_keyed_tabular(value, depth, key: "#{prefix}#{k}",
                             row_depth: rd)
      else
        push(depth, "#{prefix}#{k}:")
        encode_hash(value, child_depth)
      end

    when Array
      if value.empty?
        push(depth, "#{prefix}#{k}: []")
      elsif tabular_array?(value)
        row_depth = hyphen ? depth + 2 : depth + 1
        encode_tabular("#{prefix}#{k}", value, depth, row_depth:)
      elsif primitive_array?(value)
        line = value.map { |v| encode_scalar(v) }.join(@delimiter)
        push(depth, "#{prefix}#{k}#{length_header(value.size)}: #{line}")
      else
        push(depth, "#{prefix}#{k}#{length_header(value.size)}:")
        value.each { |item| encode_list_item(item, child_depth) }
      end

    else
      push(depth, "#{prefix}#{k}: #{encode_scalar(value)}")
    end
  end

  # Encodes an anonymous array that is itself a list item, prefixed with
  # a hyphen. Scalar arrays use inline form; anything else expands into
  # nested list items.
  #
  # @param array [Array] the list-item array
  # @param depth [Integer] the indent depth of the hyphen line
  def encode_list_array(array, depth)
    if array.empty?
      push(depth, "- #{length_header(0)}:")
    elsif primitive_array?(array)
      line = array.map { |v| encode_scalar(v) }.join(@delimiter)
      push(depth, "- #{length_header(array.size)}: #{line}")
    else
      push(depth, "- #{length_header(array.size)}:")
      array.each { |item| encode_list_item(item, depth + 1) }
    end
  end

  # Encodes an array of uniform Hashes in tabular form: a header line
  # +[n]{fields}:+ followed by one delimited row per element.
  #
  # @param key [String, nil] an optional field name prefix on the header
  # @param array [Array<Hash>] the rows to encode
  # @param depth [Integer] the indent depth for the header
  # @param row_depth [Integer] the indent depth for the data rows
  def encode_tabular(key, array, depth, row_depth: depth + 1)
    header, paths = build_field_spec(array)
    label = key ? "#{key}#{length_header(array.size)}{#{header}}:" : \
                          "#{length_header(array.size)}{#{header}}:"
    push(depth, label)

    array.each do |row|
      values = paths.map do |path|
        cell = row.dig(*path)
        encode_cell(cell)
      end
      push(row_depth, values.join(@delimiter))
    end
  end

  # Encodes a hash in keyed tabular form: a header line
  # +[n:]{fields}:+ followed by one +key: v1,v2+ row per entry.
  #
  # @param hash [Hash] the hash to encode
  # @param depth [Integer] the indent depth of the header
  # @param key [String, nil] an optional field name prefix on the header
  # @param row_depth [Integer, nil] the indent depth for entry rows
  def encode_keyed_tabular(hash, depth, key: nil, row_depth: nil)
    rd = row_depth || depth + 1
    values = hash.values
    header, paths = build_field_spec(values)
    lh = length_header(hash.size, keyed: true)
    label = key ? "#{key}#{lh}{#{header}}:" : "#{lh}{#{header}}:"
    push(depth, label)

    hash.each do |k, row|
      values_line = paths.map do |path|
        cell = row.dig(*path)
        encode_cell(cell)
      end
      push(rd, "#{encode_key(k)}: #{values_line.join(@delimiter)}")
    end
  end

  # Builds the field-group header and per-field access paths for a set of
  # row hashes. Nested uniform Hash fields collapse into +{name{...}}+
  # groups; the returned paths are key chains used to fetch each cell.
  #
  # @param rows [Array<Hash>] the row hashes
  # @return [Array(String, Array<Array<String>>)] the joined header and
  #   the list of key-path chains
  def build_field_spec(rows)
    keys  = rows.first.keys
    parts = []
    paths = []

    keys.each do |key|
      sub = rows.map { |r| r[key] }
      ek  = encode_key(key)

      if sub.all? { |v| v.is_a?(Hash) && !v.empty? } &&
         uniform_hashes?(sub)
        sub_header, sub_paths = build_field_spec(sub)
        parts.push("#{ek}{#{sub_header}}")
        sub_paths.each { |p| paths.push([key] + p) }
      else
        parts.push(ek)
        paths.push([key])
      end
    end

    [parts.join(@delimiter), paths]
  end

  # Encodes a single tabular cell. Nested Hash/Array cells are JSON-
  # encoded and quoted; +nil+ becomes "null"; everything else goes
  # through the scalar encoder.
  #
  # @param cell [Object] the cell value
  # @return [String] the encoded cell
  def encode_cell(cell)
    case cell
    when Hash, Array
      "\"#{JSON.generate(cell)}\""
    when nil
      'null'
    else
      encode_scalar(cell)
    end
  end

  # Reports whether +hash+ is eligible for keyed tabular form: at least
  # two entries, all values non-empty uniform Hashes, none containing
  # Array values.
  #
  # @param hash [Hash] the candidate hash
  # @return [Boolean] +true+ when keyed tabular form applies
  def keyed_tabular?(hash)
    return false if hash.size < 2
    values = hash.values
    return false unless values.all? { |v| v.is_a?(Hash) && !v.empty? }
    return false unless uniform_hashes?(values)
    !values.any? { |v| hash_has_array?(v) }
  end

  # Recursively reports whether any value inside +hash+ (or nested
  # hashes) is an Array.
  #
  # @param hash [Hash] the hash to inspect
  # @return [Boolean] +true+ when an Array is present
  def hash_has_array?(hash)
    hash.values.any? do |v|
      case v
      when Array then true
      when Hash  then hash_has_array?(v)
      else false
      end
    end
  end

  # Reports whether +array+ is an array of non-empty, key-uniform Hashes
  # whose fields can be flattened into tabular columns.
  #
  # @param array [Array] the candidate array
  # @return [Boolean] +true+ when the array is tabular-eligible
  def tabular_array?(array)
    !array.empty? &&
      array.all? { |v| v.is_a?(Hash) && !v.empty? } &&
      uniform_hashes?(array) &&
      tabular_leaves?(array)
  end

  # Recursively reports whether each field's values across +hashes+ are
  # either all scalars or all uniform nested Hashes without Array
  # values, so they can be flattened into tabular columns.
  #
  # @param hashes [Array<Hash>] the hashes to inspect
  # @return [Boolean] +true+ when tabular flattening is possible
  def tabular_leaves?(hashes)
    keys = hashes.first.keys
    keys.all? do |key|
      values = hashes.map { |h| h[key] }
      if values.all? { |v| v.nil? || v.is_a?(String) ||
        v.is_a?(Numeric) || v.is_a?(TrueClass) || v.is_a?(FalseClass) }
        true
      elsif values.all? { |v| v.is_a?(Hash) && !v.empty? } &&
            uniform_hashes?(values) &&
            !values.any? { |v| v.values.any? { |x| x.is_a?(Array) } }
        tabular_leaves?(values)
      else
        false
      end
    end
  end

  # Reports whether every hash in +hashes+ has the same set of keys
  # (order-insensitive), a prerequisite for tabular encoding.
  #
  # @param hashes [Array<Hash>] the hashes to compare
  # @return [Boolean] +true+ when all key sets are identical
  def uniform_hashes?(hashes)
    first = hashes.first
    keys  = first.keys
    size  = first.size
    hashes.all? { |h| h.size == size && keys.all? { |k| h.key?(k) } }
  end

  # Reports whether every element of +array+ is a TOON scalar (nil,
  # String, Numeric, or boolean), i.e. it can use inline form.
  #
  # @param array [Array] the candidate array
  # @return [Boolean] +true+ when all elements are scalars
  def primitive_array?(array)
    array.all? do |v|
      v.nil? || v.is_a?(String) || v.is_a?(Numeric) ||
        v.is_a?(TrueClass) || v.is_a?(FalseClass)
    end
  end

  # Encodes a single scalar value (nil, boolean, number, or string) into
  # its TOON representation.
  #
  # @param value [Object] the scalar to encode
  # @return [String] the encoded scalar
  def encode_scalar(value)
    case value
    when nil     then 'null'
    when true    then 'true'
    when false   then 'false'
    when Integer then value.to_s
    when Float   then encode_float(value)
    else              encode_string(value.to_s)
    end
  end

  # Encodes a +Float+ using its shortest round-trippable decimal form.
  # Whole-number floats become integers, zero becomes "0", and exponent
  # notation is expanded via BigDecimal to a plain decimal.
  #
  # @param f [Float] the float value
  # @return [String] the encoded number
  def encode_float(f)
    return '0' if f.zero?
    fi = f.to_i
    return fi.to_s if f == fi && f.abs < 1e15
    fs = f.to_s
    return fs unless fs.match?(/e/i)
    BigDecimal(fs).to_s('F')
  end

  # Encodes a scalar string value. The string is UTF-8-scrubbed, then
  # emitted bare when safe or double-quoted with escaping otherwise.
  #
  # @param str [String] the raw string value
  # @return [String] the encoded string
  def encode_string(str)
    return '""' if str.empty?

    str = str.scrub unless str.valid_encoding?

    if safe_unquoted?(str)
      str
    else
      "\"#{escape_string(str)}\""
    end
  end

  # Encodes a hash key per the TOON key-encoding rules. Bare word-like
  # keys are emitted as-is; anything resembling a number or literal, or
  # containing structural characters, is quoted and escaped.
  #
  # @param key [Object] the raw hash key
  # @return [String] the encoded key
  def encode_key(key)
    key = key.to_s
    key = key.scrub unless key.empty? || key.valid_encoding?

    if key.match?(SAFE_KEY) && !key.match?(JSON_NUMBER)
      key
    else
      "\"#{escape_string(key)}\""
    end
  end

  UNSAFE_STRING = /
      \A\#                    # comment prefix (§7.2)
    | \A\xEF\xBB\xBF[0-9.+-]  # BOM + digit: decoders strip BOM (§12)
    | \A\s                    # leadingwhitespace (§7.1)
    | \s\z                    # trailing whitespace (§7.1)
    | [\x00-\x1F:\[\]{}"\\]   # controls, reserved, structural (§7.1)
    | #{JSON_NUMBER.source}   # full JSON number (§7.3)
    | \A(?:true|false|null)\z # JSON literal (§7.3)
    | \A[+-]?\d               # number-like prefix (§7.3)
    | \A-                     # list item marker (§7.1)
  /x
  private_constant :UNSAFE_STRING

  # Reports whether +str+ can be emitted as an unquoted TOON value.
  # The UNSAFE_STRING regex covers all static structural conflicts;
  # the active delimiter is checked separately (instance state).
  #
  # @param str [String] the scrubbed candidate string
  # @return [Boolean] +true+ when the string needs no quoting
  def safe_unquoted?(str)
    return false if str.match?(UNSAFE_STRING)
    return false if str.include?(@delimiter)
    true
  end

  ESCAPE_STRING = {
    ?\0 => '\\u0000'.freeze,
    ?\a => '\\u0007'.freeze,
    ?\b => '\\u0008'.freeze,
    ?\t => '\\t'.freeze,
    ?\n => '\\n'.freeze,
    ?\v => '\\u000b'.freeze,
    ?\f => '\\u000c'.freeze,
    ?\r => '\\r'.freeze,
    ?\e => '\\u001b'.freeze,
    ?\\ => '\\\\'.freeze,
    ?"  => '\\"'.freeze,
  }
  ESCAPE_STRING.default_proc = -> _, c { format('\\u%04x', c.ord) }
  ESCAPE_STRING.freeze
  private_constant :ESCAPE_STRING

  # Escapes a string for safe inclusion inside a double-quoted TOON
  # value. Backslashes, double quotes, and C0 control characters are
  # escaped; remaining control characters are emitted as \uXXXX.
  #
  # @param str [String] the raw string to escape
  # @return [String] the escaped string (without surrounding quotes)
  def escape_string(str)
    str.gsub(/[\\"\n\r\t\x00-\x08\x0B\x0C\x0E-\x1F]/, ESCAPE_STRING)
  end
end
