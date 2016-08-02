require 'spec_helper'

describe TsdUtils::TestValidator do
  let(:tsd) { double('tsd', tsd: {}) }
  let(:subject) { TsdUtils::TestValidator.new(tsd, 'cluster') }
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

  context 'when everything valid' do
    before do
      allow_any_instance_of(TsdUtils::TsdValidator).to receive(:valid?) { true }
      allow_any_instance_of(TsdUtils::ClusterValidator).to receive(:valid?) { true }
      allow_any_instance_of(TsdUtils::TsdValidator).to receive(:errors) { [] }
      allow_any_instance_of(TsdUtils::ClusterValidator).to receive(:errors) { [] }
    end

    describe '#errors' do
      it 'is empty array' do
        expect(subject.errors).to eq []
      end
    end

    describe '#valid?' do
      it 'returns true' do
        expect(subject.valid?).to be true
      end
    end
  end

  context 'when tsd invalid' do
    before do
      allow_any_instance_of(TsdUtils::TsdValidator).to receive(:valid?) { false }
      allow_any_instance_of(TsdUtils::ClusterValidator).to receive(:valid?) { true }
      allow_any_instance_of(TsdUtils::TsdValidator).to receive(:errors) do
        [TsdUtils::ValidationIssue.new('tsd', 'description')]
      end
      allow_any_instance_of(TsdUtils::ClusterValidator).to receive(:errors) { [] }
    end

    describe '#errors' do
      it 'contains tsd item' do
        subject.valid?
        expect(subject.errors.first.context).to eq 'tsd'
      end
    end

    describe '#valid?' do
      it 'returns false' do
        expect(subject.valid?).to be false
      end
    end
  end

  context 'when cluster invalid' do
    before do
      allow_any_instance_of(TsdUtils::TsdValidator).to receive(:valid?) { true }
      allow_any_instance_of(TsdUtils::ClusterValidator).to receive(:valid?) { false }
      allow_any_instance_of(TsdUtils::TsdValidator).to receive(:errors) { [] }
      allow_any_instance_of(TsdUtils::ClusterValidator).to receive(:errors) do
        [TsdUtils::ValidationIssue.new('cluster', 'description')]
      end
    end

    describe '#errors' do
      it 'contains one item' do
        subject.valid?
        expect(subject.errors.first.context).to eq 'cluster'
      end
    end

    describe '#valid?' do
      it 'returns false' do
        expect(subject.valid?).to be false
      end
    end
  end

  context 'when both tsd and cluster invalid' do
    before do
      allow_any_instance_of(TsdUtils::TsdValidator).to receive(:valid?) { true }
      allow_any_instance_of(TsdUtils::ClusterValidator).to receive(:valid?) { false }
      allow_any_instance_of(TsdUtils::TsdValidator).to receive(:errors) do
        [TsdUtils::ValidationIssue.new('tsd', 'description')]
      end
      allow_any_instance_of(TsdUtils::ClusterValidator).to receive(:errors) do
        [TsdUtils::ValidationIssue.new('cluster', 'description')]
      end
    end

    describe '#errors' do
      it 'contains one item' do
        subject.valid?
        expect(subject.errors[0].context).to eq 'tsd'
        expect(subject.errors[1].context).to eq 'cluster'
      end
    end

    describe '#valid?' do
      it 'returns false' do
        expect(subject.valid?).to be false
      end
    end
  end
end
