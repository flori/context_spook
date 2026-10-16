# ContextSpook

ContextSpook is a Ruby library that collects and organizes project information
to help AI assistants understand codebases better. It provides a
domain-specific language (DSL) for describing project context, which can then
be exported as structured JSON or TOON (Token-Oriented Object Notation) data.

TOON output is produced by a native encoder conformant to the TOON v4.4
specification, validated against 186 official conformance fixtures.

The DSL is general-purpose and can be used for any kind of project or
collection of files, whether software development, documentation, research
data, educational materials, creative projects, or any other type of organized
information. The `.contexts/project.rb` example below demonstrates how to
describe a Ruby project, but the same principles apply across many different
domains.

## Documentation

Complete API documentation is available at:
[GitHub.io](https://flori.github.io/context_spook/)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'context_spook'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install context_spook
```

## Usage

### Programmatic Usage

#### Directly in Ruby

Now you can generate context from a block directly in Ruby using the DSL:

```ruby
context = ContextSpook::generate_context do
  context do
    variable branch: `git rev-parse --abbrev-ref HEAD`.chomp
    
    namespace "structure" do
      command "tree", tags: %w[ project_structure ]
    end
    
    namespace "lib" do
      Dir['lib/**/*.rb'].each do |filename|
        file filename, tags: 'lib'
      end
    end
    
    # ... rest of your context definition, see below for full example
  end
end
```

This approach can be used to dynamically generate a context when it is not
configurable via a user context definition file, or as a fallback when users
have not yet created such files.

Afterwards you can store the context as JSON in Ruby or send it to another
application.

```ruby
File.write 'context.json', context.to_json
```
You can also generate a manifest-only context by passing `manifest: true`.
File entries are reduced to their path plus metadata (size, tokens, MIME
types, tags), giving the model a lightweight index of file paths it can
use with `read_file` to load only what it needs:

```ruby
context = ContextSpook::generate_context(manifest: true) do
  context do
    file 'lib/context_spook.rb'
  end
end
```
#### From a context definition file

Alternatively store the block's content above to a file `.contexts/project.rb`:

```ruby
# .contexts/project.rb
context do
  variable branch: `git rev-parse --abbrev-ref HEAD`.chomp

  namespace "structure" do
    command "tree", tags: %w[ project_structure ]
  end

  namespace "lib" do
    Dir['lib/**/*.rb'].each do |filename|
      file filename, tags: 'lib'
    end
  end

  namespace "spec" do
    Dir['spec/**/*.rb'].each do |filename|
      file filename, tags: 'spec'
    end
  end

  namespace "gems" do
    file 'context_spook.gemspec'
    file 'Gemfile'
    file 'Gemfile.lock'
  end

  file 'Rakefile',  tags: 'gem_hadar'

  file 'README.md', tags: 'documentation'

  meta ruby: RUBY_DESCRIPTION

  meta code_coverage: json('coverage/coverage_context.json')
end
```

Now you can generate the context from the file, and store it as JSON in Ruby or
send it to another application.

```ruby
context = ContextSpook::generate_context('.contexts/project.rb')
File.write 'context.json', context.to_json
```

### CLI Usage

Generate context and save to file:

```bash
context_spook .contexts/project.rb > context.json
```

Or pipe directly to another tool:

```bash
context_spook .contexts/project.rb | ollama_chat_send
```

You can choose the output format with the `-F` flag (JSON is the default):

```bash
# Generate context as TOON
context_spook .contexts/project.rb -F TOON > context.toon

# Save TOON directly to a file
context_spook .contexts/project.rb -F TOON -o context.toon
```
You can use manifest mode with `-m` to omit file content. Each file entry
is reduced to its path plus metadata (size, tokens, MIME types, tags),
giving the model a lightweight index of file paths it can use with
`read_file` to load only what it needs:

```bash
# Generate manifest-only context as TOON
context_spook .contexts/project.rb -F TOON -m > context.toon

# Generate manifest-only context as JSON
context_spook .contexts/project.rb -m > context.json
```

The CLI tool also supports verbose output:

```bash
# Generate context without verbose output
context_spook .contexts/project.rb ~v
```

Now you can see two orange warning messages, that demonstrates how errors like
missing files or commands with failing exit codes are handled.

The CLI tool also supports file redirection:

```bash
# Generate context and save to file
context_spook .contexts/project.rb -o context.json
```

You can also use include patterns to automatically collect files without
manually specifying each one:

```bash
# Collect all Ruby files from lib/ and spec/ directories
context_spook -i 'lib/**/*.rb' -i 'spec/**/*.rb'

# Collect Markdown and YAML files from current directory
context_spook -i '*.md' -i '*.yaml' -i '*.yml'

# Collect files with complex patterns
context_spook -i 'lib/**/{*.rb,*.rake}'     # Brace expansion
context_spook -i 'lib/**/*_spec.rb'         # Pattern matching
context_spook -i 'lib/**/*.rb' -i 'spec/**/*_spec.rb'  # Mixed patterns
```

### Size Estimation

To estimate the size of your context without generating the large output file:

```bash
# Show context size information only
context_spook .contexts/project.rb -S
```

This is useful for optimizing context size before committing to large output
files.

This is how you can show the usage message:

```
# Show help
context_spook -h
```

## What Gets Collected

The DSL collects various types of project information:

- **Variables**: Key-value pairs (e.g., git branch)
- **Files**: Line-numbered content, byte size, token estimate, MIME types, line
  count, and tags (or metadata-only in manifest mode)
- **Commands**: Shell command outputs with size, token estimate, exit codes,
  working directory, and tags
- **Metadata**: Project-wide attributes (e.g., Ruby version, coverage data)

## Intended Use Case

The generated JSON is designed to be sent to Language Model assistants to
provide them with comprehensive context about your codebase. This helps AI
assistants understand:

- The project structure and file organization
- Key source files and their contents
- Command outputs that reveal project state
- Metadata about the development environment
- Coverage information for code quality

## Example Output Structure

```json
{
  "files": {
    "lib/context_spook.rb": {
      "namespace": "lib",
      "content": [
        { "linenumber": 1, "line": "module ContextSpook" },
        { "linenumber": 2, "line": "" },
        { "linenumber": 3, "line": "require 'context_spook/version'" },
        { "linenumber": 4, "line": "require 'context_spook/utils'" },
        { "linenumber": 5, "line": "require 'context_spook/generator'" }
      ],
      "size": 120,
      "tokens": 35,
      "lines": 5,
      "content_types": [
        "application/x-ruby",
        "text/x-ruby"
      ],
      "tags": [
        "lib"
      ]
    }
  },
  "commands": {
    "tree": {
      "namespace": "structure",
      "output": "lib\n├── context_spook\n│   └── generator.rb\n└── context_spook.rb\n\n2 directories, 3 files",
      "size": 88,
      "tokens": 26,
      "exit_code": 0,
      "working_directory": "/path/to/project",
      "tags": [
        "project_structure"
      ]
    }
  },
  "metadata": {
    "ruby": "ruby 4.0.7 (2026-09-15 ...) +PRISM [x86_64-linux]",
    "code_coverage": null
  },
  "variables": {
    "branch": "master"
  }
}
```

The same context in TOON v4 format:

```
files:
  "lib/context_spook.rb":
    namespace: lib
    content[5]{linenumber,line}:
      1,module ContextSpook
      2,""
      3,require 'context_spook/version'
      4,require 'context_spook/utils'
      5,require 'context_spook/generator'
    size: 120
    tokens: 35
    lines: 5
    content_types[2]: application/x-ruby,text/x-ruby
    tags[1]: lib
commands:
  tree:
    namespace: structure
    output: "lib\n├── context_spook\n│   └── generator.rb\n└── context_spook.rb\n\n2 directories, 3 files"
    size: 88
    tokens: 26
    exit_code: 0
    working_directory: /path/to/project
    tags[1]: project_structure
metadata:
  ruby: "ruby 4.0.7 (2026-09-15 ...) +PRISM [x86_64-linux]"
  code_coverage: null
variables:
  branch: master
```

## License

The gem is available as open source under the terms of the [MIT License](LICENSE)
