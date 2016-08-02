describe TsdUtils::Tsd do
  let(:subject) { TsdUtils::Tsd.new }

  describe '#load_uri' do
    it 'fetches tsd from given uri' do
      expect(TsdUtils::ContentFetcher).to receive(:load).with('foo').and_return('{}')
      subject.load_uri 'foo'
    end
  end

  describe '#load_content' do
    it 'loads tsd from given json' do
      subject.load_content '{"foo": "bar"}'
      expect(subject.tsd['foo']).to eq 'bar'
    end
  end

  describe '#runtime_config' do
    it 'returns runtime_config from given tsd' do
      tsd = { runtimeConfig: ['definition' => 'foo', 'value' => 'quux'] }.to_json
      subject.load_content(tsd)
      expect(subject.runtime_config).to eq('foo' => 'quux')
    end
  end
end
