describe TsdUtils::EnqueueData do
  let(:tsd) { double('tsd', tsd: {}) }
  let(:subject) { TsdUtils::EnqueueData.new enqueue_data }

  before do
    allow(tsd).to receive(:runtime_config=)
    allow(TsdUtils::Tsd).to receive(:new) { tsd }
    allow(tsd).to receive(:runtime_config) { Hash.new }
    allow(tsd).to receive(:normalize_clusters) {}
  end

  before(:all) do
    TsdUtils.config = {
      clusters: {
        frodo: 'http://shire/frodo',
        bilbo: 'http://shire/bilbo',
        sam: 'http://shire/sam',
        peregrin: 'http://shire/peregrin'
      }
    }
  end

  describe '#load_tsd' do
    context 'when "file" is present' do
      let(:tsd_file) { '{"runtimeConfig":[{"definition":"foo","value":"bar"}]}' }
      let(:enqueue_data) do
        { 'runtimeConfigFields' => {}, 'file' => tsd_file }
      end

      it 'loads tsd from enqueue data' do
        expect(tsd).to receive(:load_content)
        subject.load_tsd
      end

      context 'but empty' do
        let(:enqueue_data) do
          { 'runtimeConfigFields' => {}, 'file' => '' }
        end

        it 'raises_exception' do
          expect { subject.load_tsd }.to raise_error 'We are unable to resolve tsd source'
        end
      end
    end

    context 'when "TsdWebgitLink" is present' do
      let(:enqueue_data) do
        { 'runtimeConfigFields' => {}, 'TsdWebgitLink' => 'tsd_link' }
      end

      it 'loads tsd from uri' do
        expect(tsd).to receive(:load_uri).with('tsd_link')
        subject.load_tsd
      end

      context 'but empty' do
        let(:enqueue_data) do
          { 'runtimeConfigFields' => {}, 'TsdWebgitLink' => '' }
        end

        it 'raises_exception' do
          expect { subject.load_tsd }.to raise_error 'We are unable to resolve tsd source'
        end
      end
    end

    context 'when both "TsdWebgitLink" and "file" are present' do
      let(:tsd_file) { '{"runtimeConfig":[{"definition":"foo","value":"bar"}]}' }
      let(:enqueue_data) do
        { 'runtimeConfigFields' => {}, 'TsdWebgitLink' => 'tsd_link', 'file' => tsd_file }
      end

      it 'loads tsd from uri' do
        expect(tsd).to receive(:load_uri).with('tsd_link')
        subject.load_tsd
      end
    end

    context 'when both "TsdWebgitLink" and "file" are missing' do
      let(:enqueue_data) do
        { 'runtimeConfigFields' => {} }
      end

      it 'raises exception' do
        expect { subject.load_tsd }.to raise_error 'We are unable to resolve tsd source'
      end
    end

    context 'when both "TsdWebgitLink" and "file" are empty' do
      let(:enqueue_data) do
        { 'runtimeConfigFields' => {}, 'TsdWebgitLink' => '', 'file' => '' }
      end

      it 'raises exception' do
        expect { subject.load_tsd }.to raise_error 'We are unable to resolve tsd source'
      end
    end
  end

  context 'validation' do
    let(:path_to_test_file) { File.expand_path('./tsd_files/test_tsd.tsd', File.dirname(__FILE__)) }
    let(:tsd_file_content) { File.read(path_to_test_file) }
    let(:enqueue_data) do
      {
        'runtimeConfigFields' => {},
        'file' => '{}'
      }
    end
    let(:tsd) { double('tsd', tsd: JSON.parse(tsd_file_content)) }

    describe '#valid?' do
      it 'uses test validator' do
        expect_any_instance_of(TsdUtils::TestValidator).to receive(:valid?) { true }
        subject.valid?
      end
    end

    describe '#errors' do
      it 'uses test validator' do
        expect_any_instance_of(TsdUtils::TestValidator).to receive(:errors) { [] }
        subject.errors
      end
    end
  end

  describe '#normalize_runtime_config' do
    let(:enqueue_data) do
      { 'runtimeConfigFields' => runtime_config, 'file' => '{}' }
    end

    let(:runtime_config) { [{ 'definition' => 'baz', 'value' => 'qux' }] }

    it 'converts definition/value pairs to hash' do
      subject.normalize_runtime_config
      expected_runtime_config = { 'baz' => 'qux' }
      expect(subject.enqueue_data['RuntimeConfig']).to eq expected_runtime_config
    end
  end

  describe '#build' do
    let(:fake_builder) do
      double('fake_builder', build: 'some_fake_value')
    end

    before do
      allow(tsd).to receive(:load_content)
      allow(TsdUtils::Tsd::Builder).to receive(:new).and_return(fake_builder)
    end

    context 'when runtime config is undefined' do
      let(:enqueue_data) do
        { 'file' => '{}' }
      end

      it 'handles empty runtime config' do
        allow(tsd).to receive(:build)
        subject.load_tsd
        subject.normalize_runtime_config
        subject.build
      end
    end

    context 'when runtime config is defined' do
      let(:enqueue_data) do
        {
          'file' => '{}',
          'runtimeConfigFields' => [{ 'definition' => 'iniConfiguration', 'value' => 'unc' }]
        }
      end

      it 'interpolates handlebars in tsd' do
        expect(tsd).to receive(:build)
        subject.load_tsd
        subject.normalize_runtime_config
        subject.build
      end

      context 'when ini configuration defined in runtime config' do
        let(:enqueue_data) do
          {
            'file' => '{}',
            'runtimeConfigFields' => [{ 'definition' => 'iniConfiguration', 'value' => 'unc' }],
            'a' => 'b',
            'c' => 'd',
            'e' => 'f',
            'package' => 'test_package'
          }
        end

        before do
          allow(tsd).to receive(:build).and_return('foo_baz_quux')
        end

        it 'reads ini file' do
          expect(TsdUtils::Tsd::Builder).to receive(:new)
            .with('unc', 'iniConfiguration' => 'unc').at_least(1)

          subject.normalize_runtime_config
          subject.build
        end

        it 'interpolates every field in enqueue data' do
          subject.normalize_runtime_config
          subject.build
          result = subject.enqueue_data
          expect(result['a']).to eq 'some_fake_value'
          expect(result['c']).to eq 'some_fake_value'
          expect(result['e']).to eq 'some_fake_value'
          expect(result['Branch']).to eq 'some_fake_value'
          expect(result['enqueueAndStart']).to eq 'some_fake_value'
        end
      end

      context 'when both enqueue data and tsd runtime config defined' do
        let(:enqueue_data) do
          {
            'file' => '{ }',
            'runtimeConfigFields' => [{ 'definition' => 'enqueue_data', 'value' => 'config' }],
            'a' => 'b',
            'c' => 'd',
            'e' => 'f',
            'package' => 'test_package'
          }
        end
        let(:tsd_runtime_config) { { 'tsd' => 'config' } }

        before do
          allow(tsd).to receive(:runtime_config) { tsd_runtime_config }
          allow(tsd).to receive(:build)
        end

        it 'merges tsd runtime config to enqueue data runtime config' do
          subject.normalize_runtime_config
          subject.build
          result = subject.enqueue_data
          expect(result['RuntimeConfig']['tsd']).to eq 'some_fake_value'
          expect(result['RuntimeConfig']['enqueue_data']).to eq 'some_fake_value'
        end
      end
    end
  end

  describe '#to_enqueue_data' do
    let(:enqueue_data) do
      {
        'file' => 'foo',
        'stashTSD' => 'bar',
        'checkpoints' => 'baz',
        'scenarioScripts' => 'qux',
        'package' => 'quux',
        'strategy' => 'corge',
        'packageFrom' => 'grault',
        'runtimeConfigFields' => 'garply'
      }
    end

    it 'interprets correctly all input enqueue data fields' do
      expect(subject.enqueue_data['TsdContent']).to eq 'foo'
      expect(subject.enqueue_data['TsdWebgitLink']).to eq 'bar'
      expect(subject.enqueue_data['SaveCheckpoints']).to eq 'baz'
      expect(subject.enqueue_data['UseStartScript']).to eq 'qux'
      expect(subject.enqueue_data['Branch']).to eq 'quux'
      expect(subject.enqueue_data['StrategyName']).to eq 'corge'
      expect(subject.enqueue_data['PackageSource']).to eq 'grault'
      expect(subject.enqueue_data['RuntimeConfig']).to eq 'garply'
    end
  end

  describe '#resolve_email' do
    let(:enqueue_data) do
      {
        'file' => 'foo',
        'email' => 'garply',
        'runtimeConfigFields' => [{ 'definition' => 'email', 'value' => 'foobar' }]
      }
    end

    let(:enqueue_data_womail) do
      {
        'file' => 'foo',
        'email' => 'garply',
        'runtimeConfigFields' => [{ 'definition' => 'emaill', 'value' => 'foobar' }]
      }
    end

    it 'replaces email from runtime config in enqueue data' do
      subject.normalize_runtime_config
      subject.resolve_email
      expect(subject.enqueue_data['Email']).to eq('foobar')
    end

    it 'doesn\'t replace email from runtime config in enqueue data' do
      subject = TsdUtils::EnqueueData.new enqueue_data_womail
      subject.normalize_runtime_config
      subject.resolve_email
      expect(subject.enqueue_data['Email']).to eq('garply')
    end
  end

  describe '#resolve_strategy' do
    let(:enqueue_data) do
      {
        'file' => 'foo',
        'email' => 'garply',
        'strategyName' => 'foo'
      }
    end

    it 'replaces strategy from runtime config in tsd' do
      helper_tsd = {
        'strategy' => [{ 'name' => 'foo' }, { 'name' => 'bar' }],
        'defaultStrategy' => 'foo'
      }

      expect(tsd).to receive(:tsd).at_least(:once) { helper_tsd }
      subject.normalize_runtime_config
      subject.resolve_strategy
      expect(helper_tsd['defaultStrategy']).to eq 'foo'
    end

    it 'doesn\'t replace strategy if it is not present in tsd' do
      data = {
        'file' => 'foo',
        'email' => 'garply',
        'runtimeConfigFields' => [{ 'definition' => 'strategy', 'value' => 'A' }],
        'strategyName' => 'B'
      }

      subject = TsdUtils::EnqueueData.new data

      helper_tsd = {
        'strategy' => [{ 'name' => 'foo' }, { 'name' => 'bar' }],
        'defaultStrategy' => 'foo'
      }

      expect(tsd).to receive(:tsd).at_least(:once) { helper_tsd }
      subject.normalize_runtime_config
      subject.resolve_strategy
      expect(helper_tsd['defaultStrategy']).to eq 'foo'
    end

    it 'replaces strategy from enqueue data in tsd' do
      data = {
        'file' => 'foo',
        'email' => 'garply',
        'strategy' => 'bar'
      }

      subject = TsdUtils::EnqueueData.new data

      helper_tsd = {
        'strategy' => [{ 'name' => 'foo' }, { 'name' => 'bar' }],
        'defaultStrategy' => 'foo'
      }

      expect(tsd).to receive(:tsd).at_least(:once) { helper_tsd }
      subject.normalize_runtime_config
      subject.resolve_strategy
      expect(helper_tsd['defaultStrategy']).to eq 'bar'
    end

    it 'replaces strategy from enqueue data in tsd when both possibilities specified' do
      data = {
        'file' => 'foo',
        'email' => 'garply',
        'runtimeConfigFields' => [{ 'definition' => 'strategy', 'value' => 'baz' }],
        'strategy' => 'qux'
      }

      subject = TsdUtils::EnqueueData.new data

      helper_tsd = {
        'strategy' => [
          { 'name' => 'foo' }, { 'name' => 'bar' }, { 'name' => 'baz' }, { 'name' => 'qux' }
        ],
        'defaultStrategy' => 'foo'
      }

      expect(tsd).to receive(:tsd).at_least(:once) { helper_tsd }
      subject.normalize_runtime_config
      subject.resolve_strategy
      expect(helper_tsd['defaultStrategy']).to eq 'qux'
    end

    context 'when an array strategy in tsd doesn\'t exist' do
      it 'replaces nothing' do
        data = {
          'file' => 'foo',
          'email' => 'garply',
          'strategy' => 'bar'
        }

        subject = TsdUtils::EnqueueData.new data

        helper_tsd = {
          '_strategy' => [{ 'name' => 'foo' }, { 'name' => 'bar' }],
          '_defaultStrategy' => 'foo'
        }

        expect(tsd).to receive(:tsd).at_least(:once) { helper_tsd }
        subject.normalize_runtime_config
        subject.resolve_strategy
        expect(helper_tsd['defaultStrategy']).to eq nil
      end

      it 'doesn\'t touch defaultStrategy' do
        data = {
          'file' => 'foo',
          'email' => 'garply',
          'strategyName' => 'bar'
        }

        subject = TsdUtils::EnqueueData.new data

        helper_tsd = {
          '_strategy' => [{ 'name' => 'foo' }, { 'name' => 'bar' }],
          'defaultStrategy' => 'foo'
        }

        expect(tsd).to receive(:tsd).at_least(:once) { helper_tsd }
        subject.normalize_runtime_config
        subject.resolve_strategy
        expect(helper_tsd['defaultStrategy']).to eq 'foo'
      end
    end
  end

  describe '#clusters' do
    let(:enqueue_data) do
      {}
    end

    let(:path_to_test_file) { File.expand_path('./tsd_files/test_tsd.tsd', File.dirname(__FILE__)) }
    let(:tsd) { double('tsd', tsd: JSON.parse(File.read(path_to_test_file))) }

    strategies = [
      ['Takes all machines', %w(frodo bilbo)],
      ['Takes all XP machines', ['frodo']],
      ['Takes 7 and 8 machines', ['bilbo']],
      ['Takes XP and 7 machines', %w(frodo bilbo)],
      ['Takes XP_2, 7 and 8 machines', %w(frodo bilbo)],
      ['Takes no machines', []]
    ]

    strategies.each do |(strategy_to_test, result)|
      it "resolves correct clusters for strategy #{strategy_to_test}" do
        tsd.tsd['defaultStrategy'] = strategy_to_test
        expect(subject.clusters).to eq result
      end
    end
  end

  describe '#machine_belongs_to' do
    let(:enqueue_data) do
      { 'runtimeConfigFields' => {}, 'file' => '{}' }
    end

    machines = ['7x64', 'XP', '2k12x64', 'VISTA', '8.1x64', '8']
    test_cases = [
      [['8*'], [false, false, false, false, true, true]],
      [['8*', '7*'], [true, false, false, false, true, true]],
      [['8*', '7*', 'XP'], [true, true, false, false, true, true]],
      [['!8*'], [true, true, true, true, false, false]],
      [['!8*', '!VISTA'], [true, true, true, false, false, false]],
      [['!8*', '!VISTA', '7x64'], [true, false, false, false, false, false]],
      [['7x64', 'XP', '2k12x64', 'VISTA', '8.1x64', '8'], Array.new(6, true)],
      [[], Array.new(6, true)],
      [['8.1x64'], [false, false, false, false, true, false]],
      [['non-sens'], Array.new(6, false)],
      [['8', 'VISTAx64', '8*'], [false, false, false, false, true, true]],
      [['!*'], Array.new(6, false)],
      [['!'], Array.new(6, true)],
      [['*'], Array.new(6, true)],
      [['!7x64', '!XP', '!2k12x64', '!VISTA', '!8.1x64', '!8'], Array.new(6, false)],
      [['!7x64', '!XP', '!2k12x64', 'VISTA', '!8.1x64', '!8'],
       [false, false, false, true, false, false]],
      [['VISTA'], [false, false, false, true, false, false]],
      [['asdf*', 'XP*'], [false, true, false, false, false, false]],
      [['asdf*'], Array.new(6, false)],
      [['!asdf', 'XP'], [false, true, false, false, false, false]],
      [['!asdf'], Array.new(6, true)],
      [['!asdf*'], Array.new(6, true)],
      [['8*', '!8*'], [false, false, false, false, true, true]],
      [['!8*', '8*'], Array.new(6, false)],
      [['8*', '!8.1x64'], [false, false, false, false, true, true]],
      [['!8.1x64', '8*'], [false, false, false, false, false, true]],
      [['VISTA', '!VISTA'], [false, false, false, true, false, false]],
      [['!VISTA', 'VISTA'], Array.new(6, false)],
      [['8', 'XP', '*x64'], [false, true, false, false, false, true]]
    ]

    test_cases.each do |(test_case, expected_responses)|
      it "handles #{test_case}" do
        machines.each_with_index do |machine_name, index|
          expect(subject.send(:machine_belongs_to, machine_name, test_case))
            .to eq expected_responses[index]
        end
      end
    end

    describe '#tsd' do
      let(:tsd_file) { { 'foo' => 'bar' } }
      let(:enqueue_data) do
        { 'file' => tsd_file.to_json }
      end
      it 'returns tsd as hash' do
        expect(subject.tsd).to eq tsd_file
      end
    end

    describe '#package_source' do
      let(:tsd_file) { { 'Source' => { 'git' => 'foo' } } }
      before do
        allow(tsd).to receive(:tsd) { tsd_file }
      end

      context 'when package address specified in enqueue data' do
        let(:enqueue_data) do
          {
            'file' => tsd_file.to_json,
            'package' => 'bar'
          }
        end

        it 'returns package from enqueue data' do
          expect(subject.package_source).to eq 'bar'
        end
      end

      context 'when package address specified in tsd' do
        context 'when git specified' do
          let(:enqueue_data) do
            { 'file' => tsd_file.to_json }
          end

          it 'returns git package address' do
            expect(subject.package_source).to eq 'foo'
          end
        end

        context 'when unc specified' do
          let(:tsd_file) { { 'Source' => { 'unc' => 'bar' } } }
          let(:enqueue_data) do
            { 'file' => tsd_file.to_json }
          end

          it 'returns unc package address' do
            expect(subject.package_source).to eq 'bar'
          end
        end
      end
    end

    describe '#package_from' do
      let(:tsd_file) { { 'Source' => { 'git' => 'foo' } } }
      before do
        allow(tsd).to receive(:tsd) { tsd_file }
      end

      context 'when packagefrom specified in enqueue data' do
        let(:enqueue_data) do
          {
            'file' => tsd_file.to_json,
            'packageFrom' => 'UNC'
          }
        end

        it 'returns package source from enqueue data' do
          expect(subject.package_from).to eq 'UNC'
        end
      end

      context 'when package source specified in tsd' do
        context 'when git specified' do
          let(:enqueue_data) do
            { 'file' => tsd_file.to_json }
          end

          it 'returns git' do
            expect(subject.package_from).to eq 'GIT'
          end
        end

        context 'when unc specified' do
          let(:tsd_file) { { 'Source' => { 'unc' => 'bar' } } }
          let(:enqueue_data) do
            { 'file' => tsd_file.to_json }
          end

          it 'returns unc' do
            expect(subject.package_from).to eq 'UNC'
          end
        end
      end
    end

    describe '#email' do
      let(:tsd_file) { { 'responsible' => 'foo@bar.baz' } }
      before do
        allow(tsd).to receive(:tsd) { tsd_file }
      end

      context 'when email specified in enqueue data' do
        let(:enqueue_data) do
          {
            'TsdContent' => tsd_file.to_json,
            'email' => 'qux@quux.corge'
          }
        end

        it 'returns email from enqueue data' do
          expect(subject.email).to eq enqueue_data['email']
        end
      end

      context 'when email specified in tsd' do
        let(:enqueue_data) do
          {
            'TsdContent' => tsd_file.to_json
          }
        end

        it 'returns email from tsd' do
          expect(subject.email).to eq tsd_file['responsible']
        end
      end
    end

    describe '#description' do
      let(:tsd_file) { { 'Description' => 'grault garply waldo' } }
      before do
        allow(tsd).to receive(:tsd) { tsd_file }
      end

      context 'when description specified in enqueue data' do
        let(:enqueue_data) do
          {
            'file' => tsd_file.to_json,
            'description' => 'fred plugh xyzzy'
          }
        end

        it 'returns description from enqueue data' do
          expect(subject.description).to eq enqueue_data['description']
        end
      end

      context 'when description specified in tsd' do
        let(:enqueue_data) do
          {
            'file' => tsd_file.to_json
          }
        end

        it 'returns description from tsd' do
          expect(subject.description).to eq tsd_file['Description']
        end
      end
    end

    describe '#runtime_config' do
      let(:enqueue_data) do
        {
          'runtimeConfig' => { waldo: 'fred' }
        }
      end

      before do
        allow(tsd).to receive(:tsd) { tsd_file }
      end

      it 'returns runtime_config' do
        expected_runtime_config = [{ definition: 'waldo', value: 'fred' }]
        expect(subject.runtime_config).to eq(expected_runtime_config)
      end
    end
  end
end
