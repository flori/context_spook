context do
  variable branch: `git rev-parse --abbrev-ref HEAD`.chomp

  namespace "structure" do
    command "tree lib", tags: %w[ project_structure ]
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

  meta code_coverage: JSON.load_file('coverage/coverage_context.json') rescue nil
end
