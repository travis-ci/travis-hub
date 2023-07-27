describe Stage do
  let(:build)  { FactoryBot.create(:build, state: :started) }
  let(:stages) { [1, 2].map { |num| FactoryBot.create(:stage, build:, number: num) } }
  let(:jobs)   { ['1.1', '1.2', '2.1'].map { |num| FactoryBot.create(:job, stage_number: num, stage: stages[num.to_i - 1], build:) } }
  let(:now)    { Time.now }

  # hmm? why do i need this here??
  before do
    jobs.map(&:reload)
    Travis::Event.stubs(:dispatch)
  end

  def reload
    build.reload
    stages.map(&:reload)
    jobs.map(&:reload)
  end

  describe 'success' do
    before do
      jobs[0].finish!(state: :passed, finished_at: now)
      jobs[1].finish!(state: :passed, finished_at: now)
      jobs[2].finish!(state: :passed, finished_at: now)
      reload
    end

    it { expect(build.state).to eq :passed }
    it { expect(stages[0].state).to eq :passed }
    it { expect(stages[1].state).to eq :passed }
    it { expect(stages[0].finished_at).to eq now }
    it { expect(stages[1].finished_at).to eq now }
    it { expect(jobs[0].state).to eq :passed }
    it { expect(jobs[1].state).to eq :passed }
    it { expect(jobs[2].state).to eq :passed }
  end

  describe 'failure' do
    before do
      jobs[0].finish!(state: :failed, finished_at: now)
      jobs[1].finish!(state: :passed, finished_at: now)
      reload
    end

    it { expect(build.state).to eq :failed }
    it { expect(stages[0].state).to eq :failed }
    it { expect(stages[1].state).to eq :canceled }
    it { expect(stages[0].finished_at).to eq now }
    it { expect(stages[1].finished_at).to eq now }
    it { expect(jobs[0].state).to eq :failed }
    it { expect(jobs[1].state).to eq :passed }
    it { expect(jobs[2].state).to eq :canceled }
  end

  describe 'error' do
    before do
      jobs[0].finish!(state: :errored, finished_at: now)
      jobs[1].finish!(state: :passed, finished_at: now)
      reload
    end

    it { expect(build.state).to eq :errored }
    it { expect(stages[0].state).to eq :errored }
    it { expect(stages[1].state).to eq :canceled }
    it { expect(jobs[0].state).to eq :errored }
    it { expect(jobs[1].state).to eq :passed }
    it { expect(jobs[2].state).to eq :canceled }
  end

  describe 'with allow_failure' do
    before do
      jobs[0].update!(allow_failure: true)
      jobs[0].finish!(state: :failed, finished_at: now)
      jobs[1].finish!(state: :passed, finished_at: now)
      reload
    end

    it { expect(build.state).to eq :started }
    it { expect(stages[0].state).to eq :passed }
    it { expect(stages[1].state).to eq :created }
    it { expect(jobs[0].state).to eq :failed }
    it { expect(jobs[1].state).to eq :passed }
    it { expect(jobs[2].state).to eq :created }
  end

  describe 'with allow_failure and fast_finish' do
    before do
      build.update!(config: { matrix: { fast_finish: true } })
      jobs[1].update!(allow_failure: true)
      jobs[0].finish!(state: :failed, finished_at: now)
      reload
    end

    # i.e. the one `allow_failure` job will still be run (as it does with
    # normal matrix builds) but jobs in later stages have been canceled
    it { expect(build.state).to eq :failed }
    it { expect(stages[0].state).to eq :failed }
    it { expect(stages[1].state).to eq :canceled }
    it { expect(jobs[0].state).to eq :failed }
    it { expect(jobs[1].state).to eq :created }
    it { expect(jobs[2].state).to eq :canceled }
  end

  describe 'cancel and fail' do
    before do
      jobs[0].cancel!
      jobs[2].cancel!
      jobs[1].finish!(state: :failed, finished_at: now)
      reload
    end

    it { expect(build.state).to eq :canceled }
    it { expect(stages[0].state).to eq :canceled }
    it { expect(stages[1].state).to eq :canceled }
    it { expect(jobs[0].state).to eq :canceled }
    it { expect(jobs[1].state).to eq :failed }
    it { expect(jobs[2].state).to eq :canceled }
  end
end
