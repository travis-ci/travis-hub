describe Stage do
  before       { Travis::Event.stubs(:dispatch) }
  let(:build)  { FactoryGirl.create(:build, state: :started) }
  let(:stages) { [1, 2].map { |num| FactoryGirl.create(:stage, build: build, number: num) } }
  let(:jobs)   { ['1.1', '1.2', '2.1'].map { |num| FactoryGirl.create(:job, stage_number: num, stage: stages[num.to_i - 1], build: build) } }

  before { jobs.map(&:reload) } # hmm? why do i need this here??

  def reload
    build.reload
    jobs.map(&:reload)
  end

  describe 'failure' do
    before { jobs[0].finish!(state: :failed) }
    before { jobs[1].finish!(state: :passed) }
    before { reload }

    it { expect(build.state).to eq :failed }
    it { expect(jobs[0].state).to eq :failed }
    it { expect(jobs[1].state).to eq :passed }
    it { expect(jobs[2].state).to eq :canceled }
  end

  describe 'error' do
    before { jobs[0].finish!(state: :errored) }
    before { jobs[1].finish!(state: :passed) }
    before { reload }

    it { expect(build.state).to eq :errored }
    it { expect(jobs[0].state).to eq :errored }
    it { expect(jobs[1].state).to eq :passed }
    it { expect(jobs[2].state).to eq :canceled }
  end

  describe 'with allow_failure' do
    before { jobs[0].update_attributes!(allow_failure: true) }
    before { jobs[0].finish!(state: :failed) }
    before { jobs[1].finish!(state: :passed) }
    before { reload }

    it { expect(build.state).to eq :started }
    it { expect(jobs[0].state).to eq :failed }
    it { expect(jobs[1].state).to eq :passed }
    it { expect(jobs[2].state).to eq :created }
  end

  describe 'with allow_failure and fast_finish' do
    before { build.update_attributes!(config: { matrix: { fast_finish: true } }) }
    before { jobs[1].update_attributes!(allow_failure: true) }
    before { jobs[0].finish!(state: :failed) }
    before { reload }

    # i.e. the one `allow_failure` job will still be run (as it does with
    # normal matrix builds) but jobs in later stages has been canceled
    it { expect(build.state).to eq :failed }
    it { expect(jobs[0].state).to eq :failed }
    it { expect(jobs[1].state).to eq :created }
    it { expect(jobs[2].state).to eq :canceled }
  end
end
