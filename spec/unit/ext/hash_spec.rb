describe Hash do
  let(:subject) do
    {
      id: 1,
      name: {
        First: 'Doc',
        Last: 'Brown',
        Kids: [
          { 'Nick' => 'Jules' },
          { Nick: 'Verne' }
        ]
      }
    }
  end

  describe '#deep_stringify_keys' do
    it 'converts all symbols to strings' do
      new_hash = subject.deep_stringify_keys

      expect(new_hash['id']).to eq(1)
      expect(new_hash['name']['First']).to eq('Doc')
      expect(new_hash['name']['Last']).to eq('Brown')
      expect(new_hash['name']['Kids'].first['Nick']).to eq('Jules')
      expect(new_hash['name']['Kids'].last['Nick']).to eq('Verne')
    end
  end

  describe '#deep_downcase_keys' do
    it 'converts all keys to downcase' do
      new_hash = subject.deep_downcase_keys

      expect(new_hash[:name][:first]).to eq('Doc')
      expect(new_hash[:name][:last]).to eq('Brown')

      expect(new_hash[:name][:kids]).to eq([{ 'nick' => 'Jules' }, { nick: 'Verne' }])
      expect(new_hash[:name][:kids].first).to eq('nick' => 'Jules')
      expect(new_hash[:name][:kids].last).to eq(nick: 'Verne')
      expect(new_hash[:name][:kids].first['nick']).to eq('Jules')
      expect(new_hash[:name][:kids].last[:nick]).to eq('Verne')
    end
  end

  describe '#duplicate' do
    let(:new_hash) { subject.duplicate }

    it 'returns duplicate of original hash' do
      expect(new_hash).to eq(subject)
    end

    it 'returns duplicate with values which are not just a reference' do
      expect(new_hash[:name].equal?(subject[:name])).to be(false)

      expect(new_hash[:name][:First].equal?(subject[:name][:First])).to be(false)
      expect(new_hash[:name][:Last].equal?(subject[:name][:Last])).to be(false)

      expect(new_hash[:name][:Kids].equal?(subject[:name][:Kids])).to be(false)
      expect(new_hash[:name][:Kids].first.equal?(subject[:name][:Kids].first)).to be(false)
      expect(new_hash[:name][:Kids].last.equal?(subject[:name][:Kids].last)).to be(false)

      expect(new_hash[:name][:Kids].first['Nick'].equal?(subject[:name][:Kids].first['Nick']))
        .to be(false)

      expect(new_hash[:name][:Kids].last[:Nick].equal?(subject[:name][:Kids].last[:Nick]))
        .to be(false)
    end
  end

  context 'case sensitivity related function' do
    let(:stringy_hash) { subject.deep_stringify_keys }

    describe '#get_ikey' do
      it 'returns value, if key is nil and exists' do
        stringy_hash[nil] = 'nil-hilist'

        expect(stringy_hash.get_ikey(nil)).to eq('nil-hilist')
      end

      it 'returns value, if key exists' do
        expect(stringy_hash.get_ikey('ID')).to be(1)
      end

      it 'returns nil, if key does not exist' do
        expect(stringy_hash.get_ikey('not_really_existing')).to be(nil)
      end
    end

    describe '#has_ikey?' do
      it 'returns true, if key is nil and exists' do
        stringy_hash[nil] = 'nil-hilist'

        expect(stringy_hash.ikey?(nil)).to be(true)
      end

      it 'returns true, if key exists' do
        expect(stringy_hash.ikey?('ID')).to be(true)
      end

      it 'returns false, if key does not exist' do
        expect(stringy_hash.ikey?('not_really_existing')).to be(false)
      end
    end
  end
end
