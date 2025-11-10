context do
  variable branch: `git rev-parse --abbrev-ref HEAD`.chomp

  namespace "structure" do
    command "tree", tags: %w[ project_structure ]
  end

  namespace "bin" do
    Dir['bin/**/*'].each do |filename|
      file filename, tags: 'bin'
    end
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

  command 'false', tags: 'failure'

  command 'echo hello world'

  file 'nixda', tags: 'failure'

  file 'Rakefile',  tags: [ 'gem_hadar' ]

  file 'README.md', tags: [ 'documentation' ]

  meta ruby: RUBY_DESCRIPTION

  meta hello_world: json('hello_world.json')

  meta nixda_json: json('nixda_json.json')

  meta hey_world: yaml('hey_world.yaml')

  meta nixda_yaml: yaml('nixda_yaml.yaml')

  meta code_coverage: json('coverage/coverage_context.json')
end
