require 'spec_helper'

describe ContextSpook::TOON do
  let(:my_context) do
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
      toon_output = my_context.to_toon
      expect(toon_output).to be_a(String)
      expect(toon_output).to_not be_empty
    end

    it 'produces valid TOON output' do
      toon_output = my_context.to_toon
      expect(toon_output).to match(
        %r{
          \Afiles:\n
          ^[ ]{2}"lib/context_spook\.rb":\n
          ^[ ]{4}content:[ ]"[^"]+"\n
          ^[ ]{4}size:[ ]120\n
          ^[ ]{4}lines:[ ]5\n
          ^[ ]{4}content_types\[2\]:[ ]application/x-ruby,text/x-ruby\n
          ^commands:\n
          ^metadata:\n
          ^[ ]{2}version:[ ]"1\.0"\n
          ^[ ]{2}format:[ ]JSON\n
          ^variables:\n
          ^[ ]{2}foo:[ ]bar\z
        }x
      )
    end
  end

  describe '#toon_size' do
    it 'returns the size of TOON representation in bytes' do
      size = my_context.toon_size
      expect(size).to be_a(Integer)
      expect(size).to be > 0
    end

    it 'matches the size of the TOON output' do
      size = my_context.toon_size
      toon_output = my_context.to_toon
      expect(size).to eq(toon_output.size)
    end
  end

  describe 'integration with ContextSpook::Generator::Context' do
    it 'is included in Context class' do
      expect(my_context).to respond_to(:to_toon)
      expect(my_context).to respond_to(:toon_size)
    end

    it 'works with context data' do
      toon_output = my_context.to_toon
      expect(toon_output).to include('variables:')
      expect(toon_output).to include('metadata:')
      expect(toon_output).to include('files:')
      expect(toon_output).to include('commands:')
    end
  end
end
