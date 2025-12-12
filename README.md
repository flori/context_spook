# ContextSpook

ContextSpook is a Ruby library that collects and organizes project information
to help AI assistants understand codebases better. It provides a
domain-specific language (DSL) for describing project context, which can then
be exported as structured JSON data.

The DSL is general-purpose and can be used for any kind of project or
collection of files, whether software development, documentation, research
data, educational materials, creative projects, or any other type of organized
information. The `.contexts/project.rb` example below demonstrates how to
describe a Ruby project, but the same principles apply across many different
domains.

## Documentation

Complete API documentation is available at: [GitHub.io](https://flori.github.io/context_spook/)

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
./bin/context_spook .contexts/project.rb > context.json
```

Or pipe directly to another tool:

```bash
./bin/context_spook .contexts/project.rb | ollama_chat_send
```


The CLI tool also supports verbose output:

```bash
# Generate context without verbose output
./bin/context_spook .contexts/project.rb ~v
```

Now you can see two orange warning messages, that demonstrates how errors like
missing files or commands with failing exit codes are handled.

The CLI tool also supports file redirection:

```bash
# Generate context and save to file
./bin/context_spook .contexts/project.rb -o context.json
```

You can also use directory globbing to automatically collect files without
manually specifying each one:

```bash
# Collect all Ruby files from lib/ and spec/ directories
./bin/context_spook -d lib -d spec -s rb

# Collect Markdown and YAML files from current directory
./bin/context_spook -s md -s yaml
```

This is how you can show the usage message:

```
# Show help
./bin/context_spook -h
```

## What Gets Collected

The DSL collects various types of project information:

- **Variables**: Key-value pairs (e.g., git branch)
- **Files**: Content, size, line count, and tags for each file
- **Commands**: Shell command outputs with exit codes and working directory
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
      "content": "...",
      "size": 1234,
      "lines": 56,
      "tags": [
        "lib"
      ]
    }
  },
  "commands": {
    "tree": {
      "namespace": "structure",
      "output": "lib\n├── context_spook\n│   └── generator.rb\n└── context_spook.rb\n\n2 directories, 3 files",
      "exit_code": 0,
      "working_directory": "/path/to/project"
    }
  },
  "metadata": {
    "ruby": "ruby 3.1.0 ...",
    "code_coverage": {}
  },
  "variables": {
    "branch": "main"
  }
}
```

## License

The gem is available as open source under the terms of the [MIT License](./LICENSE)
