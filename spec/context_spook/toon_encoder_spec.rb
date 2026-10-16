# frozen_string_literal: true

require 'spec_helper'
require 'json'

# Conformance spec: drives ContextSpook::TOON::Encoder against the official
# TOON v4 encode fixtures from the toon-format-spec repository.
#
# Each fixture file is a JSON document:
#   { "tests": [ { "name", "input", "expected", ["options"], ["minSpecVersion"] } ] }
#
# We load every encode fixture, iterate the test cases, encode via our
# encoder, and compare the output string.
#
# Fixtures with minSpecVersion above our target are skipped.

describe ContextSpook::TOON::Encoder do
  FIXTURES_DIR = File.expand_path('../fixtures/encode', __dir__)
  MAX_SPEC_VERSION = '4.4'

  describe '.new' do
    it 'can output to IO' do
      io = StringIO.new
      encoder = described_class.new(output: io)
      encoder.encode(%w[ hello world ], 0)
      expect(io.string).to eq '[2]: hello,world'
    end

    it 'can output to StringArray' do
      encoder = described_class.new
      encoder.encode(%w[ hello world ], 0)
      expect(encoder.to_s).to eq '[2]: hello,world'
    end
  end

  def self.fixture_files
    Dir[File.join(FIXTURES_DIR, '*.json')].sort
  end

  def self.version_ok?(fixture)
    return true unless (ver = fixture['minSpecVersion'])
    ver.version <= MAX_SPEC_VERSION.version
  end

  fixture_files.each do |path|
    data = JSON.parse(File.read(path))
    category = File.basename(path, '.json')

    describe "fixture: #{category}" do
      data['tests'].each do |test|
        name = test['name']
        input = JSON.parse(JSON.generate(test['input']))

        # Skip tests for spec versions we haven't implemented yet
        if self.version_ok?(test)
          it name do
            options = test['options'] || {}
            delimiter = options['delimiter'] || ','
            indent    = (options['indentSize'] || 2)

            actual = described_class.encode(
              input, indent: indent, delimiter:
            )
            expected = test['expected']

            if actual == expected
              # pass
            else
              # Pretty diff for debugging
              expected_lines = expected.lines
              actual_lines   = actual.lines
              diff_lines = []
              max_len = [expected_lines.size, actual_lines.size].max
              (0...max_len).each do |i|
                e = expected_lines[i] || '<missing>'
                a = actual_lines[i] || '<missing>'
                diff_lines << "  #{i + 1}: expected #{e.inspect}  got #{a.inspect}" \
                  unless e == a
              end
              raise "TOON mismatch:\n#{diff_lines.join("\n")}"
            end
          end
        else
          skip "#{name} (requires spec v#{test['minSpecVersion']}, max: #{MAX_SPEC_VERSION})" do
          end
        end
      end
    end
  end
end
