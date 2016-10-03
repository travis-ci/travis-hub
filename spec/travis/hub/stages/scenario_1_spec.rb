describe Travis::Hub::Stages::Stage do
  let(:jobs) { keys.map { |stage| { state: :created, stage: stage } } }
  let(:root) { described_class.build(jobs) }

  include Support::Stages

  describe 'scenario 1' do
    # 1.1 \
    # 1.2 - 2.1 - 3.1
    # 1.3 /

    let(:keys)  { ['1.1', '1.2', '1.3', '2.1', '3.1'] }

    describe 'structure' do
      let :structure do
        <<-str.gsub(/ {10}/, '').chomp
          Root
            Stage key=1
              Job key=1.1 state=created
              Job key=1.2 state=created
              Job key=1.3 state=created
            Stage key=2
              Job key=2.1 state=created
            Stage key=3
              Job key=3.1 state=created
        str
      end

      it { expect(root.inspect).to eq structure }
    end

    describe 'flow' do
      context do
        it { expect(startable).to eq ['1.1', '1.2', '1.3'] }
      end

      context do
        before { start '1.1', '1.2', '1.3' }
        it { expect(startable).to eq [] }
      end

      context do
        before { finish '1.1' }
        before { start '1.2', '1.3' }
        it { expect(startable).to eq [] }
      end

      context do
        before { finish '1.1', '1.3' }
        before { start '1.2' }
        it { expect(startable).to eq [] }
      end

      context do
        before { finish '1.1', '1.2', '1.3' }
        it { expect(startable).to eq ['2.1'] }
      end

      context do
        before { finish '1.1', '1.2', '1.3' }
        before { start '2.1' }
        it { expect(startable).to eq [] }
      end

      context do
        before { finish '1.1', '1.2', '1.3', '2.1' }
        it { expect(startable).to eq ['3.1'] }
      end
    end
  end
end
