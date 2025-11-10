# vim: set filetype=ruby et sw=2 ts=2:

require 'gem_hadar'

GemHadar do
  name        'context_spook'
  module_type :module
  author      'Florian Frank'
  email       'flori@ping.de'
  homepage    "https://github.com/flori/context_spook"
  summary     "#{name} collects project context for AI"

  description <<~EOT
    #{name} is a library that collects and organizes project
    information to help AI assistants understand codebases better.
  EOT

  test_dir    'spec'
  ignore      '.*.sw[pon]', 'pkg', 'Gemfile.lock', '.AppleDouble', '.bundle',
    '.yardoc', 'doc', 'tags', 'errors.lst', 'cscope.out', 'coverage', 'tmp',
    'yard', 'TODO.md'
  package_ignore '.all_images.yml', '.tool-versions', '.gitignore', 'VERSION',
     '.rspec', '.github'
  readme      'README.md'

  executables 'context_spook'

  github_workflows(
    'static.yml' => {}
  )

  required_ruby_version  '~> 3.1'

  dependency 'tins',           '~>1.39'
  dependency 'json',           '~>2.0'
  dependency 'term-ansicolor', '~> 1.11'
  dependency 'mize',           '~> 0.6'
  dependency 'mime-types',     '~> 3.0'
  dependency 'yaml',           '~> 0.4'
  dependency 'pathname',       '~> 0.4'
  development_dependency 'all_images', '~> 0.6'
  development_dependency 'rspec',      '~> 3.2'
  development_dependency 'debug'
  development_dependency 'simplecov'

  licenses << 'MIT'

  clobber 'coverage'
end
