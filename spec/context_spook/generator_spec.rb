require 'spec_helper'

describe ContextSpook::Generator do
  let :context do
    ContextSpook.generate_context('.contexts/project.rb', verbose: true)
  end

  it 'context can be generated from block' do
    expect_any_instance_of(described_class).to\
      receive(:output_context_size).and_call_original
    context = ContextSpook.generate_context do
      context do
        variable foo: 'bar'
        metadata version: '1.0'
      end
    end
    expect(context).to be_a described_class::Context
    expect(context.variables[:foo]).to eq 'bar'
    expect(context.metadata[:version]).to eq '1.0'
  end

  it 'context can be generated from filename' do
    expect_any_instance_of(described_class).to\
      receive(:output_context_size).and_call_original
    expect(context).to be_a described_class::Context
    expect(context.metadata[:ruby]).to eq RUBY_DESCRIPTION
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
    context_as_json = context.to_json
    expect(context.size).to be > 1024
    expect(JSON(context_as_json)).to be_a Hash
  end

  describe 'Context' do
    it 'can have variables' do
      expect(context.variables[:branch]).to be_present
    end

    it 'can have files' do
      file = context.files['lib/context_spook.rb']
      expect(file).to be_present
      expect(file[:content]).to be_present
      expect(file[:content_types]).to be_present
      expect(file[:size]).to be > 0
      expect(file[:lines]).to be > 0
      expect(file[:namespace]).to eq :lib
      expect(file[:tags]).to eq %w[ lib ]
    end

    it 'can have commands' do
      command = context.commands['tree']
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
      expect(context.metadata[:ruby]).to eq RUBY_DESCRIPTION
    end

    it 'can have json metadata' do
      expect(context.metadata[:hello_world]).to eq("hello" => "world")
    end

    it 'can have yaml metadata' do
      expect(context.metadata[:hey_world]).to eq("hey" => "world")
    end
  end
end
