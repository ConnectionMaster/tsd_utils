
describe TsdUtils::ContentFetcher do
  before do
    allow(TsdUtils::SMB).to receive(:unc?) { true }
    allow(TsdUtils::SMB).to receive(:read) {}
    allow(TsdUtils::Stash).to receive(:stash_https_link?) {}
    allow(TsdUtils::Stash).to receive(:fetch_file) {}
    allow(HTTParty).to receive(:get) { double('fake_http_get', body: {}) }
  end

  describe 'when tsd source is unc path' do
    it 'checks whether the uri is samba uri' do
      smb_path = '\\\\aa\\bb\\cc\\dd\\ee\\ff'
      TsdUtils::ContentFetcher.load(smb_path)
      expect(TsdUtils::SMB).to have_received(:unc?).with(smb_path)
    end

    it 'downloads from unc via Samba' do
      smb_path = '\\\\aa\\bb\\cc\\dd\\ee\\ff'
      TsdUtils::ContentFetcher.load(smb_path)
      expect(TsdUtils::SMB).to have_received(:read)
    end
  end
end
