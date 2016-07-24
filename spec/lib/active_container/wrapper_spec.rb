require 'spec_helper'

RSpec.describe ActiveContainer::Wrapper  do
  subject { described_class.new record }

  let(:record)             { OpenStruct.new }
  let(:child_object_class) { OpenStruct }

  let(:child_wrapper) do
    Class.new(ActiveContainer::Wrapper) do
      def self.name
        'FooBarWrapper'
      end
    end
  end

  describe '.new' do
    context 'given an object' do
      before { expect(record).to be_a OpenStruct }

      it 'uses the object as the record' do
        expect(subject.record).to eq record
      end
    end

    context 'given a hash' do
      subject { child_wrapper.new record }

      let(:record) { {:foo => 'bar'} }

      before do
        allow(Kernel)
          .to receive(:const_get)
          .with('FooBar')
          .and_return child_object_class
      end

      it 'creates a new object based on the parent class of the wrapper' do
        expect(subject.record.foo).to eq 'bar'
      end
    end
  end

  describe '.wrap' do
    context 'given a call to itself' do
      subject { described_class.wrap record }

      context 'given a child wrapper exists' do
        before do
          allow(Kernel)
            .to receive(:const_get)
            .with('OpenStructWrapper')
            .and_return child_wrapper
        end

        it 'returns the wrapped record' do
          expect(subject.class).to eq child_wrapper
          expect(subject.record).to eq record
        end
      end

      context 'given a child wrapper does not exist' do
        it 'raises an error' do
          expect{subject}.to raise_error NameError,
            /uninitialized constant Kernel::OpenStructWrapper/
        end
      end

      context 'given no record' do
        let(:record) { nil }

        it 'returns nil' do
          expect(subject).to eq nil
        end
      end
    end

    context 'given a call to a child' do
      subject { child_wrapper.wrap record }

      before do
        allow(Kernel)
          .to receive(:const_get)
          .with('FooBar')
          .and_return child_object_class
      end

      it 'returns the wrapped record' do
        expect(subject.class).to eq child_wrapper
        expect(subject.record).to eq record
      end
    end
  end

  describe '.wrap_collection' do
    subject { described_class.wrap_collection records }

    let(:records) { ['record-1', 'record-2', 'record-3'] }

    context 'given an array of records' do
      before do
        allow(Kernel)
          .to receive(:const_get)
          .with('StringWrapper')
          .and_return child_wrapper
      end

      it 'maps them to wrapped objects' do
        expect(subject.map(&:record)).to eq records
      end
    end

    context 'given nothing' do
      let(:records) { nil }

      it 'returns an empty array' do
        expect(subject).to eq []
      end
    end
  end

  describe '.delegate' do
    subject { child_wrapper.new record }

    let(:record) { OpenStruct.new(:foo => 'bar', :bar => 'baz') }

    let(:child_wrapper) do
      Class.new(described_class) do
        def bar=(value)
          @record.bar = 'u cant touch this!'
        end

        delegate :foo, :bar
      end
    end

    it 'delegates the getter to the record' do
      expect(subject.foo).to eq 'bar'
    end

    it 'delegates the setter to the record' do
      subject.foo = 'qux'
      expect(subject.foo).to eq 'qux'
    end

    context 'given the setter is already defined on the wrapper' do
      it 'uses the setter on the wrapper' do
        expect(subject.bar).to eq 'baz'
        subject.bar = 'baz'
        expect(subject.bar).to eq 'u cant touch this!'
      end
    end
  end

  describe '.wrap_delegate' do
    subject { child_wrapper.new record }

    let(:record) { OpenStruct.new(:foo => 'bar', :bars => ['baz-1', 'baz-2']) }

    let(:child_wrapper) do
      Class.new(described_class) do
        wrap_delegate :foo, :bars
      end
    end

    before do
      allow(Kernel)
        .to receive(:const_get)
        .with('StringWrapper')
        .and_return child_wrapper
    end

    context 'given a singular method' do
      it 'returns the wrapped result' do
        expect(subject.foo.record).to eq 'bar'
      end
    end

    context 'given a plural method' do
      it 'returns the wrapped records' do
        expect(subject.bars.map(&:record)).to eq ['baz-1', 'baz-2']
      end
    end
  end

  describe '.object_class' do
    context 'given itself' do
      it 'returns nil' do
        expect(described_class.object_class).to eq nil
      end
    end

    context 'given a subclass with a matching object class' do
      let(:child_object_class) { 'foo-bar-class' }

      let(:child_wrapper) do
        Class.new(ActiveContainer::Wrapper) do
          def self.name
            'BazCacheWrapper'
          end
        end
      end

      before do
        allow(Kernel)
          .to receive(:const_get)
          .with('BazCache')
          .and_return(child_object_class)
          .exactly(1)
      end

      it 'returns the child object class and caches it' do
        expect(child_wrapper.object_class).to eq child_object_class
        expect(child_wrapper.object_class).to eq child_object_class
      end
    end

    context 'given something with a name that does not match' do
      it 'raises an error' do
        expect{child_wrapper.object_class}.to raise_error NameError,
          /uninitialized constant Kernel::FooBar/
      end
    end
  end

  describe '#wrapped?' do
    it 'returns true' do
      expect(subject.wrapped?).to eq true
    end
  end

  shared_examples_for 'instance delegate' do |method|
    subject { child_wrapper.new record }

    let(:record) do
      klass = Class.new do
        def self.add_method(method, value)
          define_method method do
            return value
          end
        end
      end

      klass.add_method method, "#{method}-value"

      klass.new
    end

    before do
      allow(Kernel)
        .to receive(:const_get)
        .with('OpenStructWrapper')
        .and_return child_wrapper
    end

    it 'returns the value from the record' do
      expect(subject.send(method)).to eq "#{method}-value"
    end
  end

  it_behaves_like 'instance delegate', :id
end
