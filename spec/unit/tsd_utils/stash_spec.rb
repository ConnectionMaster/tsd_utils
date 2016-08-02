describe TsdUtils::Stash do
  describe '::fetch_file' do
    let(:http_response) { double('fake_stderr', body: {}) }
    let(:expected_uri) { 'https://fake.com?raw=' }

    it 'adds raw to query, if not present' do
      expect(HTTParty).to receive(:get).with(expected_uri, any_args) { http_response }
      TsdUtils::Stash.fetch_file('https://fake.com')
    end

    context 'does not add raw to query' do
      it 'is already present' do
        expect(HTTParty).to receive(:get).with(expected_uri, any_args) { http_response }
        TsdUtils::Stash.fetch_file('https://fake.com?raw=')
      end

      it 'is present as first in many fields' do
        uri = 'https://fake.com?raw=good&one=two'

        expect(HTTParty).to receive(:get).with(uri, any_args) { http_response }
        TsdUtils::Stash.fetch_file(uri)
      end

      it 'is present somewhere in many fields' do
        uri = 'https://fake.com?one=two&raw=&three=four'

        expect(HTTParty).to receive(:get).with(uri, any_args) { http_response }
        TsdUtils::Stash.fetch_file(uri)
      end
    end
  end

  describe '::stash_https_link?' do
    context 'returns false when uri' do
      it 'is invalid' do
        expect(TsdUtils::Stash.stash_https_link?('bla')).to be false
      end

      it 'is not HTTPS' do
        expect(TsdUtils::Stash.stash_https_link?('http://stash.com/')).to be false
      end

      it 'is not Stash related' do
        expect(TsdUtils::Stash.stash_https_link?('https://some-dummy-page.io/')).to be false
      end
    end

    context 'returns true when uri' do
      it 'is correct Stash one' do
        expect(TsdUtils::Stash.stash_https_link?('https://stash.com/')).to be true
      end
    end
  end
end
