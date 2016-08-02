describe TsdUtils::Tsd::Builder do
  let(:subject) { TsdUtils::Tsd::Builder.new ini_file_unc, runtime_config }
  let(:ini_file_unc) { '\\\\foo\\bar' }
  let(:runtime_config) { {} }
  let(:ini_file) { '' }

  before do
    allow(TsdUtils::ContentFetcher).to receive(:load).and_return(ini_file)
  end

  describe '#ini_file_data' do
    it 'loads ini file using given unc' do
      expect(TsdUtils::ContentFetcher).to receive(:load).with(ini_file_unc)
      subject.ini_file_data
    end

    context 'when called multiple times' do
      it 'loads ini file exactly once' do
        expect(TsdUtils::ContentFetcher).to receive(:load).once
        subject.ini_file_data
        subject.ini_file_data
      end
    end

    context 'when ini file unc not specified' do
      let(:ini_file_unc) { nil }

      it 'returns empty hash' do
        expect(subject.ini_file_data).to eq({})
      end
    end

    context 'when ini file loading raises error' do
      before do
        allow(TsdUtils::ContentFetcher).to receive(:load).and_raise(TestError)
      end

      it 'it reraises the error' do
        expect { subject.ini_file_data }.to raise_error(TestError)
      end
    end

    context 'when parsing raises error' do
      before do
        allow(IniParse).to receive(:parse).and_raise(TestError)
      end

      it 'it reraises the error' do
        expect { subject.ini_file_data }.to raise_error(TestError)
      end
    end
  end

  describe '#expanded_runtime_config' do
    let(:runtime_config) { { foo: '{{runtimeConfig.bar}}', bar: 'baz' } }

    it 'interpolates handlebars in runtime config' do
      expected_runtime_config = { foo: 'baz', bar: 'baz' }
      expect(subject.expanded_runtime_config.symbolize_keys).to eq expected_runtime_config
    end
  end

  describe '#build' do
    let(:ini_file) do
      '[qux]
  quux=corge'
    end

    it 'interpolates ini handlebars in given string' do
      input = '{{ini.qux.quux}}'
      expect(subject.build(input)).to eq 'corge'
    end

    context 'with both runtime config and ini handlebars' do
      let(:runtime_config) { { foo: '{{ini.qux.quux}}' } }

      it 'interpolates ini handlebars in runtime config first' do
        input = '{{runtimeConfig.foo}}'
        expect(subject.build(input)).to eq 'corge'
      end
    end
  end
end

class TestError < StandardError
end
