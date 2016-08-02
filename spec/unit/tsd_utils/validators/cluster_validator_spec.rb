require 'spec_helper'

describe TsdUtils::ClusterValidator do
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

  context 'for 1 existing cluster' do
    let(:subject) { TsdUtils::ClusterValidator.new(['frodo']) }

    describe '#errors' do
      it 'is empty array' do
        subject.valid?
        expect(subject.errors).to eq []
      end
    end

    describe '#valid?' do
      it 'returns true' do
        expect(subject.valid?).to be true
      end
    end
  end

  context 'for 1 not existing cluster' do
    let(:subject) { TsdUtils::ClusterValidator.new(['gollum']) }

    describe '#errors' do
      it 'contains description' do
        subject.valid?
        expect(subject.errors.first.description).to eq '"gollum" is not a supported cluster.'
      end

      it 'has "cluster" context' do
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

  context 'for multiple clusters' do
    let(:subject) { TsdUtils::ClusterValidator.new(%w(frodo gandalf)) }

    describe '#errors' do
      it 'contains description' do
        subject.valid?
        expect(subject.errors[0].description)
          .to eq 'One cluster allowed, found: ["frodo", "gandalf"].'
      end

      it 'has "cluster" context' do
        subject.valid?
        expect(subject.errors[0].context).to eq 'cluster'
      end
    end

    describe '#valid?' do
      it 'returns false' do
        expect(subject.valid?).to be false
      end
    end
  end

  context 'in case of undefined valid clusters' do
    let(:subject) { TsdUtils::ClusterValidator.new(['frodo']) }

    it 'throws RuntimeError' do
      TsdUtils.config = nil
      expect { subject.valid? }
        .to raise_error 'TsdUtils are not configured properly to validate clusters.'
    end
  end
end
