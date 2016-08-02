require 'spec_helper'

describe TsdUtils::TsdValidator do
  let(:subject)   { TsdUtils::TsdValidator.new }
  let(:test_tsd)  { '{ "a":"b", "c":"d"}' }
  let(:stdin)     { double('fake_stdin', write: {}, close: {}) }
  let(:stdout)    { double('fake_stdout') }
  let(:stderr)    { double('fake_stderr', read: {}) }
  let(:pr_result) { double('fake process result') }
  let(:thrid)     { double('fake_thrid', value: pr_result) }

  before :all do
    TsdUtils.config = {
      executable: 'TsdValidator',
      executable_params: '-dv'
    }
  end

  before :each do
    subject.tsd = test_tsd
    allow(Open3).to receive(:popen3)
      .and_yield(stdin, stdout, stderr, thrid)
  end

  context '#valid?' do
    it 'calls Open3#popen3' do
      expect(Open3).to receive(:popen3)
        .with({}, 'mono', './bin/TsdValidator', '-dv')
      expect(pr_result).to receive(:exitstatus) { nil }
      subject.valid?
    end

    it 'passes tsd string as the stdin of the validator process' do
      expect(stdin).to receive(:write).with(test_tsd)
      expect(pr_result).to receive(:exitstatus) { nil }
      subject.valid?
    end

    it 'closes the stdin of the validator process' do
      expect(stdin).to receive(:close)
      expect(pr_result).to receive(:exitstatus) { nil }
      subject.valid?
    end

    it 'reads the content of stderr and that content is accessible via #errors' do
      expect(stderr).to receive(:read) { 'some-error-message' }
      expect(pr_result).to receive(:exitstatus) { nil }
      subject.valid?
      expect(subject.errors.first.description).to eq 'some-error-message'
    end

    context 'handles return code correctly' do
      context 'when app returns 0' do
        it 'responds with true' do
          expect(pr_result).to receive(:exitstatus) { 0 }
          expect(subject.valid?).to be true
        end

        it 'leaves errors empty' do
          expect(pr_result).to receive(:exitstatus) { 0 }
          subject.valid?
          expect(subject.errors).to eq []
        end
      end

      context 'when app returns non-zero' do
        it 'responds with false' do
          expect(pr_result).to receive(:exitstatus) { 122 }
          expect(subject.valid?).to be false
        end

        it 'leaves errors described' do
          expect(pr_result).to receive(:exitstatus) { 122 }
          subject.valid?
          expect(subject.errors).to_not eq []
        end
      end
    end
  end
end
