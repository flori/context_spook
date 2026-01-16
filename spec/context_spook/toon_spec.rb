require 'spec_helper'

describe ContextSpook::TOON do
  let(:context) do
    ContextSpook.generate_context do
      context do
        variable foo: 'bar'
        metadata version: '1.0'
        file 'lib/context_spook.rb'
      end
    end
  end

  describe '#to_toon' do
    it 'converts context to TOON format' do
      toon_output = context.to_toon
      expect(toon_output).to be_a(String)
      expect(toon_output).to_not be_empty
    end

    it 'produces valid TOON output' do
      toon_output = context.to_toon
      # TOON should be a valid string representation
      expect { RubyJsonToon.decode(toon_output) }.not_to raise_error
    end
  end

  describe '#toon_size' do
    it 'returns the size of TOON representation in bytes' do
      size = context.toon_size
      expect(size).to be_a(Integer)
      expect(size).to be > 0
    end

    it 'matches the size of the TOON output' do
      size = context.toon_size
      toon_output = context.to_toon
      expect(size).to eq(toon_output.size)
    end
  end

  describe 'integration with ContextSpook::Generator::Context' do
    it 'is included in Context class' do
      expect(context).to respond_to(:to_toon)
      expect(context).to respond_to(:toon_size)
    end

    it 'works with context data' do
      toon_output = context.to_toon
      expect(toon_output).to include('variables:')
      expect(toon_output).to include('metadata:')
      expect(toon_output).to include('files:')
      expect(toon_output).to include('commands:')
    end
  end
end
