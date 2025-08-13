require 'tins/xt'
require 'term/ansicolor'
require 'json'
require 'mize'

# The ContextSpook module serves as a namespace container for collecting and
# organizing project information for AI assistance.
module ContextSpook
  include DSLKit::Interpreter

  # The generate_context method processes a context definition file and returns
  # the resulting context object.
  #
  # This method reads the content of a specified file, parses it using the
  # generator's parsing mechanism, and extracts the configured context from the
  # parsed result.
  #
  # @param filename [ String ] the path to the context definition file to be processed
  #
  # @return [ ContextSpook::Generator::Context ] the context object generated
  # from the file contents
  def self.generate_context(filename = nil, &block)
    filename.present? ^ block or
      raise ArgumentError, 'need either a filename or a &block argument'
    generator = if filename
                Generator.send(:new).send(:parse, File.read(filename))
                else
                  Generator.send(:new, &block)
                end
    generator.output_context_size
    generator.context
  end

  # The Generator class provides a DSL parser that interprets context
  # definition files and constructs structured context objects containing
  # project metadata, file contents, command outputs, and variables for AI
  # assistance.
  class Generator
    private_class_method :new

    # The initialize method sets up the object by evaluating the provided block in the object's context.
    #
    # @param block [ Proc ] A block of code to be evaluated within the object's context.
    #                       If no block is given, the method does nothing.
    def initialize(&block)
      block and instance_eval(&block)
    end

    # The context method creates or returns a context object.
    #
    # @param block [ Proc ] optional block to initialize the context
    #
    # @return [ Context ] the context object
    def context(&block)
      if block
        @context and raise ArgumentError, "only one context allowed"
        @context = Context.new(&block)
      else
        @context
      end
    end

    # The output_context_size method prints the total size of the generated
    # context JSON representation.
    #
    # This method calculates the size of the context object when serialized to
    # JSON, formats it using binary units (KiB, MiB, etc.), and outputs the
    # result to standard error.
    def output_context_size
      context_size = @context&.size.to_i
      json_content_size = Tins::Unit.format(
        context_size, format: '%.2f %U', unit: ?b, prefix: 1024
      )
      STDERR.puts "Built #{json_content_size} of JSON context in total."
    end

    # The Context class represents and manages project context data, providing
    # structured storage for file contents, command outputs, variables, and
    # metadata that can be serialized to JSON for AI assistance.
    class Context
      include Tins::Scope
      include Tins::DSLAccessor
      include Term::ANSIColor

      # The initialize method sets up the object by evaluating a block in the
      # object's context.
      #
      # @param block [ Proc ] A block to be evaluated within the object's context.
      def initialize(&block)
        block and instance_eval(&block)
      end

      # The namespace method creates a scoped block with a given name.
      #
      # @param name [ Object ] the name to scope the block with
      #
      # @yield [ block ] executes the block within the created scope
      def namespace(name, &block)
        name = name.to_sym
        scope_block(name) do
          instance_eval(&block)
        end
        nil
      end

      # The variables method sets up a DSL accessor for managing a collection of
      # variables.
      #
      # @param default [ Hash ] the default variables to initialize with
      dsl_accessor :variables do
        {}
      end

      # The variable method assigns key-value pairs to the variables hash.
      #
      # @param v [ Hash ] a hash containing variable names as keys and their
      # values
      def variable(**v)
        v.each do |name, value|
          variables[name.to_sym] = value
        end
        nil
      end

      # The metadata method sets up a DSL accessor for metadata configuration.
      #
      # @param default [ Object ] the default value for the metadata, `{}`
      dsl_accessor :metadata do
        {}
      end

      # The meta method assigns metadata key-value pairs to the metadata hash.
      #
      # @param m [ Hash ] a hash of metadata key-value pairs to be added
      def meta(**m)
        m.each do |name, value|
          metadata[name.to_sym] = value
        end
        nil
      end

      # The json method reads and parses a JSON file, returning the parsed data
      # structure.
      #
      # This method attempts to load a JSON file from the specified path and
      # returns the resulting Ruby data structure. It provides verbose output
      # about the file size when successfully reading the file. In case of file
      # not found errors, it outputs a colored warning message to standard
      # error and returns nil.
      #
      # @param filename [ String ] the path to the JSON file to be read and parsed
      #
      # @return [ Object, nil ] the parsed JSON data structure or nil if the file cannot be read
      def json(filename)
        file_size = Tins::Unit.format(
          File.size(filename), format: '%.2f %U', unit: ?b, prefix: 1024
        )
        STDERR.puts "Read #{filename.inspect} as JSON (%s) for context." % file_size
        JSON.load_file(filename)
      rescue Errno::ENOENT => e
        STDERR.puts color(208) { "Reading #{filename.inspect} as JSON caused #{e.class}: #{e}" }
        nil
      end

      # The files method sets up a DSL accessor for providing files.
      #
      # @param default [ Hash ] the default files hash
      dsl_accessor :files do
        {}
      end

      # The file method associates a file with the current scope and stores its
      # content.
      #
      # It reads the specified file and creates an entry in the files hash with
      # the file's content, along with its namespace and optional tags.
      #
      # @param filename [ String ] the path to the file to be read and stored
      # @param tags [ Array<String>, nil ] optional array of tags to associate with the file
      #
      # @return [ Hash ] the created file entry with content, namespace, and tags
      def file(filename, tags: nil)
        content = File.read(filename)
        files[filename] = {
          namespace: scope_top,
          content:,
          size: content.size,
          lines: content.lines.size,
          tags: (Array(tags) if tags),
        }.compact
        file_size = Tins::Unit.format(
          content.size, format: '%.2f %U', unit: ?b, prefix: 1024
        )
        STDERR.puts "Read #{filename.inspect} (%s) for context." % file_size
        nil
      rescue Errno::ENOENT => e
        STDERR.puts color(208) { "Reading #{filename.inspect} caused #{e.class}: #{e}" }
      end

      # The commands method sets up a DSL accessor for provided command outputs.
      #
      # @param value [ Hash ] the hash of commands to be set
      dsl_accessor :commands, {}

      # The command method executes a shell command and stores its result.
      #
      # This method runs a given shell command and records the output, exit code,
      # working directory, and optional tags in the commands hash.
      #
      # @param shell_command [ String ] the shell command to execute
      # @param tags [ Array<String>, nil ] optional array of tags to associate
      # with the command
      #
      # @return [ Hash ] the stored command result including output, exit code,
      # and metadata
      def command(shell_command, tags: nil)
        output = `#{shell_command}`
        exit_code = $?&.exitstatus.to_i
        if exit_code != 0
          STDERR.puts color(208) { "Executing #{shell_command.inspect} resulted in exit code #{exit_code}." }
        end
        commands[shell_command] = {
          namespace: scope_top,
          output:,
          exit_code:,
          working_directory: Dir.pwd,
          tags: (Array(tags) if tags),
        }.compact
        output_size = Tins::Unit.format(
          output.size, format: '%.2f %U', unit: ?b, prefix: 1024
        )
        STDERR.puts "Executed #{shell_command.inspect} with output (%s) for context." % output_size
        nil
      end

      # The to_json method converts the object to a JSON representation by
      # first generating its hash form and then serializing that hash into JSON
      # format.
      memoize method:
      def to_json(*)
        as_json.to_json(*)
      end

      # The as_json method converts the context's files, commands, and metadata
      # into a hash representation.
      #
      # @return [ Hash ] a hash containing the files, commands, and metadata
      def as_json(*)
        {
          files:,
          commands:,
          metadata:,
          variables:
        }
      end

      # The size method calculates and returns the byte size of the JSON
      # representation of the context.
      #
      # This method determines the size in bytes of the JSON-serialized version
      # of the context object, which is useful for understanding the total data
      # payload being sent to an AI assistant.
      #
      # @return [ Integer ] the size in bytes of the JSON representation of the
      # context
      def size
        to_json.size
      end
    end

    private

    # The parse method processes the given source code by interpreting it
    # within the current binding context, allowing for dynamic evaluation and
    # configuration setup.
    #
    # @param source [ String ] the source code to be parsed and interpreted
    #
    # @return [ ContextSpook::Generator ] returns self to allow for method
    # chaining after parsing
    def parse(source)
      interpret_with_binding source, binding
      self
    end
  end
end
