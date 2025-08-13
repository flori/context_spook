require 'spec_helper'

describe ContextSpook::Generator do
  let :context do
    ContextSpook.generate_context('contexts/project.rb')
  end

  it 'context can be generated' do
    expect(context).to be_a described_class::Context
    expect(context.metadata[:ruby]).to eq RUBY_DESCRIPTION
  end

  it 'context be transformed to JSON if loaded' do
    context_as_json = context.to_json
    expect(context_as_json.size).to be > 1024
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
      expect(file[:size]).to be > 0
      expect(file[:lines]).to be > 0
      expect(file[:namespace]).to eq :lib
      expect(file[:tags]).to eq %w[ lib ]
    end

    it 'can have commands' do
      command = context.commands['tree']
      expect(command).to be_present
      expect(command[:working_directory]).to eq Dir.pwd
      expect(command[:exit_code]).to be_present
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
  end
end
