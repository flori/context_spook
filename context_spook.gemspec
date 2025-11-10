# -*- encoding: utf-8 -*-
# stub: context_spook 0.7.1 ruby lib

Gem::Specification.new do |s|
  s.name = "context_spook".freeze
  s.version = "0.7.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Florian Frank".freeze]
  s.date = "1980-01-02"
  s.description = "context_spook is a library that collects and organizes project\ninformation to help AI assistants understand codebases better.\n".freeze
  s.email = "flori@ping.de".freeze
  s.executables = ["context_spook".freeze]
  s.extra_rdoc_files = ["README.md".freeze, "lib/context_spook.rb".freeze, "lib/context_spook/generator.rb".freeze, "lib/context_spook/version.rb".freeze]
  s.files = [".contexts/project.rb".freeze, "Gemfile".freeze, "LICENSE".freeze, "README.md".freeze, "Rakefile".freeze, "bin/context_spook".freeze, "context_spook.gemspec".freeze, "hello_world.json".freeze, "hey_world.yaml".freeze, "lib/context_spook.rb".freeze, "lib/context_spook/generator.rb".freeze, "lib/context_spook/version.rb".freeze, "spec/context_spook/generator_spec.rb".freeze, "spec/spec_helper.rb".freeze]
  s.homepage = "https://github.com/flori/context_spook".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--title".freeze, "ContextSpook - context_spook collects project context for AI".freeze, "--main".freeze, "README.md".freeze]
  s.required_ruby_version = Gem::Requirement.new("~> 3.1".freeze)
  s.rubygems_version = "3.7.2".freeze
  s.summary = "context_spook collects project context for AI".freeze
  s.test_files = ["spec/context_spook/generator_spec.rb".freeze, "spec/spec_helper.rb".freeze]

  s.specification_version = 4

  s.add_development_dependency(%q<gem_hadar>.freeze, ["~> 2.8".freeze])
  s.add_development_dependency(%q<all_images>.freeze, ["~> 0.6".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.2".freeze])
  s.add_development_dependency(%q<debug>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<simplecov>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<tins>.freeze, ["~> 1.46".freeze])
  s.add_runtime_dependency(%q<json>.freeze, ["~> 2.0".freeze])
  s.add_runtime_dependency(%q<term-ansicolor>.freeze, ["~> 1.11".freeze])
  s.add_runtime_dependency(%q<mize>.freeze, ["~> 0.6".freeze])
  s.add_runtime_dependency(%q<mime-types>.freeze, ["~> 3.0".freeze])
  s.add_runtime_dependency(%q<yaml>.freeze, ["~> 0.4".freeze])
  s.add_runtime_dependency(%q<pathname>.freeze, ["~> 0.4".freeze])
end
