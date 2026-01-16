require 'spec_helper'

describe ContextSpook::Generator do
  let :my_context do
    ContextSpook.generate_context('.contexts/project.rb', verbose: false)
  end

  describe 'generating w/o verbose' do
    it 'context can be generated from block' do
      expect_any_instance_of(described_class).to\
        receive(:output_context_size).and_call_original
      my_context = ContextSpook.generate_context do
        context do
          variable foo: 'bar'
          metadata version: '1.0'
        end
      end
      expect(my_context).to be_a described_class::Context
      expect(my_context.variables[:foo]).to eq 'bar'
      expect(my_context.metadata[:version]).to eq '1.0'
    end

    it 'context can be generated from filename' do
      expect_any_instance_of(described_class).to\
        receive(:output_context_size).and_call_original
      expect(my_context).to be_a described_class::Context
      expect(my_context.metadata[:ruby]).to eq RUBY_DESCRIPTION
    end

    it 'could handle premature output_context_size calls' do
      expect_any_instance_of(described_class).to\
        receive(:output_context_size).and_call_original
      described_class.send(:new).output_context_size
    end

    it 'cannot do from block and filename' do
      expect {
        ContextSpook.generate_context('.contexts/project.rb') { }
      }.to raise_error(ArgumentError, /need either a filename or a &block/)
    end

    it 'context be transformed to JSON if loaded' do
      context_as_json = my_context.to_json
      expect(my_context.size).to be > 1024
      expect(JSON(context_as_json)).to be_a Hash
    end

    it 'can output context in JSON' do
      output = StringIO.new
      expect_any_instance_of(described_class).to receive(:output_context).
        with(output:).and_call_original
      my_context.generator.output_context(output:)
      expect(output.string).to include '"ruby":%s' % RUBY_DESCRIPTION.dump
    end

    it 'can output context in TOON' do
      my_context = ContextSpook.generate_context(
        '.contexts/project.rb', verbose: false, format: 'TOON'
      )
      output = StringIO.new
      expect_any_instance_of(described_class).to receive(:output_context).
        with(output:).and_call_original
      my_context.generator.output_context(output:)
      expect(output.string).to include 'ruby: %s' % RUBY_DESCRIPTION.dump
    end
  end

  describe 'generating with verbose' do
    let :my_context do
      ContextSpook.generate_context('.contexts/project.rb', verbose: true)
    end

    it 'can output context size' do
      expect_any_instance_of(described_class).to receive(:output_context_size).
        and_call_original
      expect_any_instance_of(described_class).to receive(:verbose_puts).
        with(/Built.*of JSON context in total/)
      allow_any_instance_of(described_class::Context).to receive(:verbose_puts)
      my_context
    end
  end

  describe 'Context' do
    it 'can have variables' do
      expect(my_context.variables[:branch]).to be_present
    end

    it 'can have files' do
      file = my_context.files['lib/context_spook.rb']
      expect(file).to be_present
      expect(file[:content]).to be_present
      expect(file[:content_types]).to be_present
      expect(file[:size]).to be > 0
      expect(file[:lines]).to be > 0
      expect(file[:namespace]).to eq :lib
      expect(file[:tags]).to eq %w[ lib ]
    end

    it 'can have commands' do
      command = my_context.commands['tree']
      expect(command).to be_present
      expect(command[:working_directory]).to eq Dir.pwd
      expect(command[:exit_code]).not_to be_nil
      if command[:exit_code] == 0
        expect(command[:output]).to be_present
      else
        expect(command[:output]).not_to be_present
      end
      expect(command[:tags]).to eq %w[ project_structure ]
    end

    it 'can have metada' do
      expect(my_context.metadata[:ruby]).to eq RUBY_DESCRIPTION
    end

    it 'can have json metadata' do
      expect(my_context.metadata[:hello_world]).to eq("hello" => "world")
    end

    it 'can have yaml metadata' do
      expect(my_context.metadata[:hey_world]).to eq("hey" => "world")
    end

    it 'handles missing json files gracefully' do
      expect(my_context.json('nixda.json')).to be_nil
    end

    it 'handles invalid json content gracefully' do
      Tempfile.create('invalid.json') do |f|
        f.write('{ invalid json }')
        f.close
        expect(my_context.json(f.path)).to be_nil
      end
    end

    it 'handles missing yaml files gracefully' do
      expect(my_context.yaml('nixda.yaml')).to be_nil
    end

    it 'handles invalid yaml content gracefully' do
      Tempfile.create('invalid.yaml') do |f|
        f.write('invalid: [yaml')
        f.close
        expect(my_context.yaml(f.path)).to be_nil
      end
    end
  end
end
