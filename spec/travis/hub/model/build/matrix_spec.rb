describe Build::Matrix do
  let(:config) { {} }
  let(:jobs)   { attrs.map { |attrs| FactoryGirl.create(:job, attrs) } }
  let(:matrix) { described_class.new(jobs, config) }

  describe 'duration' do
    let(:attrs) do
      [
        { state: :passed, started_at: Time.now, finished_at: nil },
        { state: :passed, started_at: Time.now, finished_at: Time.now + 60 },
        { state: :passed, started_at: Time.now, finished_at: Time.now + 120 }
      ]
    end

    it { expect(matrix.duration).to eq 180 }
  end

  describe 'with all jobs being required' do
    describe 'with all jobs being :started' do
      let(:attrs) { [{ state: :started }, { state: :started }] }

      describe 'with fast_finish being true' do
        let(:config) { { fast_finish: true } }
        it { expect(matrix.finished?).to eq false }
        it { expect { matrix.state }.to raise_error(Build::InvalidMatrixState) }
      end

      describe 'with fast_finish being false' do
        let(:config) { { fast_finish: false } }
        it { expect(matrix.finished?).to eq false }
        it { expect { matrix.state }.to raise_error(Build::InvalidMatrixState) }
      end
    end

    describe 'with all jobs being :passed' do
      let(:attrs) { [{ state: :passed }, { state: :passed }] }

      describe 'with fast_finish being true' do
        let(:config) { { fast_finish: true } }
        it { expect(matrix.finished?).to eq true }
        it { expect(matrix.state).to eq :passed }
      end

      describe 'with fast_finish being false' do
        let(:config) { { fast_finish: false } }
        it { expect(matrix.finished?).to eq true }
        it { expect(matrix.state).to eq :passed }
      end
    end

    describe 'with all jobs being :failed' do
      let(:attrs) { [{ state: :failed }, { state: :failed }] }

      describe 'with fast_finish being true' do
        let(:config) { { fast_finish: true } }
        it { expect(matrix.finished?).to eq true }
        it { expect(matrix.state).to eq :failed }
      end

      describe 'with fast_finish being false' do
        let(:config) { { fast_finish: false } }
        it { expect(matrix.finished?).to eq true }
        it { expect(matrix.state).to eq :failed }
      end
    end
  end

  describe 'with not all jobs being required' do
    describe 'with the non-required job being :started' do
      let(:attrs) { [{ state: :passed, allow_failure: false }, { state: :started, allow_failure: true }] }

      describe 'with fast_finish being true' do
        let(:config) { { fast_finish: true } }
        it { expect(matrix.finished?).to eq true }
        it { expect(matrix.state).to eq :passed }
      end

      describe 'with fast_finish being false' do
        let(:config) { { fast_finish: false } }
        it { expect(matrix.finished?).to eq false }
        it { expect(matrix.state).to eq :passed }
      end
    end

    describe 'with the non-required job being :passed' do
      let(:attrs) { [{ state: :passed, allow_failure: false }, { state: :passed, allow_failure: true }] }

      describe 'with fast_finish being true' do
        let(:config) { { fast_finish: true } }
        it { expect(matrix.finished?).to eq true }
        it { expect(matrix.state).to eq :passed }
      end

      describe 'with fast_finish being false' do
        let(:config) { { fast_finish: false } }
        it { expect(matrix.finished?).to eq true }
        it { expect(matrix.state).to eq :passed }
      end
    end

    describe 'with the non-required job being :failed' do
      let(:attrs) { [{ state: :passed, allow_failure: false }, { state: :failed, allow_failure: true }] }

      describe 'with fast_finish being true' do
        let(:config) { { fast_finish: true } }
        it { expect(matrix.finished?).to eq true }
        it { expect(matrix.state).to eq :passed }
      end

      describe 'with fast_finish being false' do
        let(:config) { { fast_finish: false } }
        it { expect(matrix.finished?).to eq true }
        it { expect(matrix.state).to eq :passed }
      end
    end
  end
end
