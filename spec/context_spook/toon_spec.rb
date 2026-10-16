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
      expect(toon_output).to start_with(
        "files:\n" \
         "  \"lib/context_spook.rb\":\n" \
        "    content[5]{linenumber,line}:\n" \
        "      1,module ContextSpook\n"
      )
      expect(toon_output).to include("    size: 120\n")
      expect(toon_output).to include("    lines: 5\n")
      expect(toon_output)
        .to include("    content_types[2]: application/x-ruby,text/x-ruby\n")
      expect(toon_output).to include("commands:\n")
      expect(toon_output).to include("  version: \"1.0\"\n")
      expect(toon_output).to include("  format: JSON\n")
      expect(toon_output).to include("variables:\n")
      expect(toon_output).to end_with("  foo: bar")
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
      expect(size).to eq(toon_output.bytesize)
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
