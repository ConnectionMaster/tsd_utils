describe TsdUtils::SMB do
  describe '::read' do
    let(:valid_unc) { 'smb://my/path/file.txt' }
    let(:invalid_unc) { 'http://IAmWeb.com/' }
    let(:error_causing_unc) { 'smb://my/path/to/perdition' }

    context 'on Windows' do
      before :each do
        allow(File).to receive(:read).with(valid_unc).and_return('file contents on Windows')
        allow(File).to receive(:read).with(error_causing_unc).and_raise(Errno::ENOENT)

        allow(Gem).to receive(:win_platform?).and_return(true)
      end

      it 'returns content of file' do
        expect(TsdUtils::SMB.read(valid_unc)).to eq('file contents on Windows')
      end

      it 'raises exception for invalid UNC' do
        expect { TsdUtils::SMB.read(invalid_unc) }.to raise_error(ArgumentError)
      end

      it 'raises exception for error causing UNC' do
        expect { TsdUtils::SMB.read(error_causing_unc) }.to raise_error(TsdUtils::SMB::SMBReadError)
      end
    end

    context 'on non-Windows OS' do
      let(:status_ok) { double('status', success?: true) }
      let(:status_fail) { double('status', success?: false) }

      before :each do
        allow(Gem).to receive(:win_platform?).and_return(false)
      end

      it 'returns content of file' do
        expect(Open3).to receive(:capture3)
          .with(any_args).and_return(['file contents on UNIX', '', status_ok])

        expect(TsdUtils::SMB.read(valid_unc)).to eq('file contents on UNIX')
      end

      it 'raises exception for invalid UNC' do
        expect { TsdUtils::SMB.read(invalid_unc) }.to raise_error(ArgumentError)
      end

      it 'raises exception for error causing UNC' do
        expect(Open3).to receive(:capture3)
          .with(any_args).and_return([nil, 'Unable to find file', status_fail])

        expect { TsdUtils::SMB.read(error_causing_unc) }.to raise_error(TsdUtils::SMB::SMBReadError)
      end
    end
  end

  describe '::unc?' do
    it 'recognizes valid unc' do
      expect(TsdUtils::SMB.unc?('//path/to/somewhere')).to be true
    end

    it 'recognizes samba specification as valid unc' do
      expect(TsdUtils::SMB.unc?('smb://is/a/kind/of/dance')).to be true
    end

    it 'recognizes invalid unc' do
      expect(TsdUtils::SMB.unc?('http://www.some-dummy-page.io/')).to be false
    end
  end

  describe '::normalize_unc' do
    it 'ensures that only forward slashes are used' do
      expect(TsdUtils::SMB.normalize_unc('smb://path\to/nowhere')).to eq('smb://path/to/nowhere')
    end

    it 'ensures smb prefix' do
      expect(TsdUtils::SMB.normalize_unc('//path/to/nowhere')).to eq('smb://path/to/nowhere')
    end

    it 'does not alter valid unc' do
      path = 'smb://path/to/nowhere'
      expect(TsdUtils::SMB.normalize_unc(path)).to eq(path)
    end

    it 'forces smb protocol' do
      expect(TsdUtils::SMB.normalize_unc('ftp://path/to/nowhere')).to eq('smb://path/to/nowhere')
    end
  end
end
