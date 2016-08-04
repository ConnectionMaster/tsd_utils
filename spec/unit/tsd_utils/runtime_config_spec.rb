describe TsdUtils::RuntimeConfig do
  describe '#merge' do
    let(:base) do
      {
        'A' => 'alpha',
        'B' => 'beta',
        'c' => 'gamma',
        'd' => 'delta',
        'Z' => 'is dead',
        'somefield' => 'original value'
      }
    end
    let(:override) do
      {
        'a' => 'adam',
        'B' => 'betty',
        'C' => 'cumberbatch',
        'd' => 'dumbledore',
        'e' => 'ekranoplan',
        'SOMEfield' => 'new value'
      }
    end

    let(:merged) { TsdUtils::RuntimeConfig.merge(base, override) }

    it 'overrides existing fields' do
      expect(merged['a']).to eq('adam')
      expect(merged['B']).to eq('betty')
      expect(merged['C']).to eq('cumberbatch')
      expect(merged['d']).to eq('dumbledore')
      expect(merged['SOMEfield']).to eq('new value')
    end

    it 'adds fields not present in base' do
      expect(merged.key?('e')).to be(true)
      expect(merged['e']).to be(override['e'])
    end

    it 'keeps the fields present only in base' do
      expect(merged.key?('Z')).to be(true)
      expect(merged['Z']).to be(base['Z'])
    end
  end
end
