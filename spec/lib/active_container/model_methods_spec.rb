require 'spec_helper'

RSpec.describe ActiveContainer::ModelMethods do
  subject { object }

  let(:object) do
    Class.new do
      include ActiveContainer::ModelMethods
      def self.name
        'FooBar'
      end
    end.new
  end

  let(:wrapper) do
    Class.new(ActiveContainer::Wrapper) do
      def self.name
        'FooBarWrapper'
      end
    end
  end

  describe '#wrapped?' do
    it 'returns false' do
      expect(subject.wrapped?).to eq false
    end
  end

  describe '#wrap' do
    subject { object.wrap }

    before do
      allow(Kernel)
        .to receive(:const_get)
        .with('FooBarWrapper')
        .and_return wrapper
    end

    it 'returns a container with the object inside' do
      expect(subject).to be_a ActiveContainer::Wrapper
      expect(subject.record).to eq object
    end
  end
end
