require 'json-compare'

def add_default_values(enqueue_data)
  data = JSON.parse(enqueue_data['EnqueueData']['TsdContent'])

  ensure_value(data, 'post', 'notifyResponsible', false)
  ensure_value(data, 'timeout', 'type', 'Floating')
  ensure_value(data, 'environment', 'type', 'Dynamic')

  enqueue_data['EnqueueData']['TsdContent'] = data.to_json

  enqueue_data
end

def ensure_value(hash, parent, subkey, value)
  hash[parent][subkey] = value if hash[parent].nil? || hash[parent][subkey].nil?
end

# rubocop:disable AbcSize
def expect_xml_is_equal(obtained, expected)
  obtained_xml = Hash.from_xml(obtained)
  expected_xml = add_default_values(Hash.from_xml(expected))

  obtained_xml['EnqueueData'].each do |key, value|
    if key == 'TsdContent'
      result = JsonCompare.get_diff(JSON.parse(value), JSON.parse(expected_xml['EnqueueData'][key]))
      expect(result).to eq({})
    elsif key == 'RuntimeConfig'
      runtime_config = Hash.from_xml(obtained_xml['EnqueueData'][key])
      expected_runtime_config = Hash.from_xml(expected_xml['EnqueueData'][key])
      result = JsonCompare.get_diff(runtime_config, expected_runtime_config)
      expect(result).to eq({})
    else
      expect(value).to eq expected_xml['EnqueueData'][key]
    end
  end
end
# rubocop:enable AbcSize

def load_data(file)
  data = JSON.parse(File.read(File.expand_path("./#{file}.json", File.dirname(__FILE__))))
  data['file'] = JSON.parse(
    File.read(File.expand_path("./#{file}.tsd", File.dirname(__FILE__)))
  ).to_json

  data
end

def load_ini(file)
  File.read(File.expand_path("./#{file}.ini", File.dirname(__FILE__)))
end

def load_expected_data(file)
  File.read(File.expand_path("./#{file}.xml", File.dirname(__FILE__)))
end

describe 'TsdUtils::EnqueueData instancing' do
  let(:subject) { TsdUtils::EnqueueData.new(load_data('test_data_01')) }

  it 'sets enqueueAndStart to true by default' do
    expect(subject.enqueue_data['enqueueAndStart']).to be(true)
  end
end

describe 'TsdUtils::EnqueueData.prepare_xml integration' do
  before(:all) do
    TsdUtils.config = {
      clusters: {
        frodo: 'http://shire/frodo',
        bilbo: 'http://shire/bilbo'
      }
    }
  end

  let(:fake_tsd_validator) { double('tsd_validator', valid?: true, errors: []) }

  before do
    allow(TsdUtils::TsdValidator).to receive(:new) { fake_tsd_validator }
  end

  context 'input without replacements' do
    let(:test_data)     { load_data('test_data_01') }
    let(:expected_data) { load_expected_data('test_data_01') }
    let(:fake_builder)  { double('fake_builder') }

    it 'generates correct enqueue data' do
      enqueue_data = TsdUtils::EnqueueData.new(test_data)
      enqueue_data.build_all
      allow(TsdUtils::Tsd::Builder).to receive(:new) { fake_builder }
      allow(fake_builder).to receive(:build) { |arg| arg }
      expect_xml_is_equal(enqueue_data.to_xml, expected_data)
    end
  end

  context 'input with ini path replacement' do
    let(:test_data_ini) { load_ini('test_data_ini_config') }
    let(:test_data)     { load_data('test_data_02') }
    let(:expected_data) { load_expected_data('test_data_02') }

    it 'generates correct enqueue data' do
      enqueue_data = TsdUtils::EnqueueData.new(test_data)

      expect(TsdUtils::ContentFetcher).to receive(:load)
        .exactly(3).times
        .with('test_data_ini_config.ini') { test_data_ini }

      enqueue_data.build_all

      expect_xml_is_equal(enqueue_data.to_xml, expected_data)
    end
  end

  context 'with ini configuration' do
    let(:test_data_ini) { load_ini('test_data_ini_config') }
    let(:test_data)     { load_data('test_data_ini_config') }
    let(:expected_data) { load_expected_data('test_data_ini_config') }

    it 'generates correct enqueue data' do
      enqueue_data = TsdUtils::EnqueueData.new(test_data)
      expect(TsdUtils::ContentFetcher).to receive(:load).exactly(4).times { test_data_ini }
      enqueue_data.build_all
      expect_xml_is_equal(enqueue_data.to_xml, expected_data)
    end
  end

  context 'with runtime config handlebars' do
    let(:test_file_name)  { 'test_data_handlebars' }
    let(:test_data)       { load_data(test_file_name) }
    let(:expected_data)   { load_expected_data(test_file_name) }

    it 'generates correct enqueue data' do
      enqueue_data = TsdUtils::EnqueueData.new(test_data)
      enqueue_data.build_all
      expect_xml_is_equal(enqueue_data.to_xml, expected_data)
    end
  end

  context 'with runtime config handlebars with hierarchical dependencies' do
    let(:test_file_name)  { 'test_data_hierarchy' }
    let(:test_data)       { load_data(test_file_name) }
    let(:expected_data)   { load_expected_data(test_file_name) }

    it 'generates correct enqueue data' do
      enqueue_data = TsdUtils::EnqueueData.new(test_data)
      enqueue_data.build_all
      expect_xml_is_equal(enqueue_data.to_xml, expected_data)
    end
  end
end
