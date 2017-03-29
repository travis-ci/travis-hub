describe Stage do
  before       { Travis::Event.stubs(:dispatch) }
  let(:build)  { FactoryGirl.create(:build, state: :started) }
  let(:stages) { [1, 2].map { |num| FactoryGirl.create(:stage, build: build, number: num) } }
  let(:jobs)   { ['1.1', '1.2', '2.1'].map { |num| FactoryGirl.create(:job, stage_number: num, stage: stages[num.to_i - 1], build: build) } }
  let(:now)    { Time.now }

  before { jobs.map(&:reload) } # hmm? why do i need this here??

  def reload
    build.reload
    stages.map(&:reload)
    jobs.map(&:reload)
  end

  if ENV['BUILD_STAGES']
    describe 'failure' do
      before { jobs[0].finish!(state: :failed, finished_at: now) }
      before { jobs[1].finish!(state: :passed, finished_at: now) }
      before { reload }

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
      before { jobs[0].finish!(state: :errored, finished_at: now) }
      before { jobs[1].finish!(state: :passed, finished_at: now) }
      before { reload }

      it { expect(build.state).to eq :errored }
      it { expect(stages[0].state).to eq :errored }
      it { expect(stages[1].state).to eq :canceled }
      it { expect(jobs[0].state).to eq :errored }
      it { expect(jobs[1].state).to eq :passed }
      it { expect(jobs[2].state).to eq :canceled }
    end

    describe 'with allow_failure' do
      before { jobs[0].update_attributes!(allow_failure: true) }
      before { jobs[0].finish!(state: :failed, finished_at: now) }
      before { jobs[1].finish!(state: :passed, finished_at: now) }
      before { reload }

      it { expect(build.state).to eq :started }
      it { expect(stages[0].state).to eq :passed }
      it { expect(stages[1].state).to eq :created }
      it { expect(jobs[0].state).to eq :failed }
      it { expect(jobs[1].state).to eq :passed }
      it { expect(jobs[2].state).to eq :created }
    end

    describe 'with allow_failure and fast_finish' do
      before { build.update_attributes!(config: { matrix: { fast_finish: true } }) }
      before { jobs[1].update_attributes!(allow_failure: true) }
      before { jobs[0].finish!(state: :failed, finished_at: now) }
      before { reload }

      # i.e. the one `allow_failure` job will still be run (as it does with
      # normal matrix builds) but jobs in later stages have been canceled
      it { expect(build.state).to eq :failed }
      it { expect(stages[0].state).to eq :failed }
      it { expect(stages[1].state).to eq :canceled }
      it { expect(jobs[0].state).to eq :failed }
      it { expect(jobs[1].state).to eq :created }
      it { expect(jobs[2].state).to eq :canceled }
    end
  end
end
