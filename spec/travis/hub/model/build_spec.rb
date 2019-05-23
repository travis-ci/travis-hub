describe Build do
  let(:state)  { :created }
  let(:params) { {} }
  let(:repo)   { FactoryGirl.create(:repository) }
  let(:build)  { FactoryGirl.create(:build, repository: repo, state: state) }
  let(:job)    { FactoryGirl.create(:job) }
  let(:now)    { Time.now }
  # before       { Travis::Event.stubs(:dispatch) }

  def receive
    build.send(:"#{event}!", params)
  end

  shared_examples 'cancels the build' do
    it 'sets :state to :canceled' do
      receive
      expect(build.reload.state).to eql(:canceled)
    end

    it 'sets :canceled_at' do
      receive
      expect(build.reload.canceled_at).to eql(now)
    end

    it 'sets :finished_at' do
      receive
      expect(build.reload.finished_at).to eql(now)
    end

    it 'dispatches a build:canceled event' do
      Travis::Event.expects(:dispatch).with('build:canceled', anything)
      receive
    end

    describe 'with all other jobs being finished' do
      let(:job) { FactoryGirl.create(:job, build: build, state: :canceled, finished_at: now, started_at: now - 2.minute) }

      it 'sets the build to :canceled' do
        receive
        expect(build.reload.state).to eql(:canceled)
      end

      it 'sets :duration' do
        job
        receive
        expect(build.reload.duration.to_i).to eql(job.duration.to_i)
      end

      it 'sets :canceled_at' do
        receive
        expect(build.reload.canceled_at).to eql(now)
      end
    end

    describe 'with jobs pending' do
      before { FactoryGirl.create(:job, build: build, state: :started) }

      it 'does not set the build to :canceled' do
        receive
        expect(build.reload.state).to_not eql(:canceled)
      end
    end

    describe 'it denormalizes to the repository' do
      %w(state duration finished_at).each do |attr|
        it "sets last_build_#{attr}" do
          receive
          expect(repo.reload.send(:"last_build_#{attr}").to_s).to eql(build.reload.send(attr).to_s)
        end
      end
    end
  end

  shared_examples 'restarts the build' do
    it 'sets :state to :created' do
      receive
      expect(build.reload.state).to eql(:created)
    end

    it 'resets :received_at' do
      receive
      expect(build.reload.received_at).to be_nil
    end

    it 'resets :started_at' do
      receive
      expect(build.reload.started_at).to be_nil
    end

    it 'resets :finished_at' do
      receive
      expect(build.reload.finished_at).to be_nil
    end

    it 'resets :canceled_at' do
      receive
      expect(build.reload.canceled_at).to be_nil
    end

    it 'sets :restarted_at' do
      receive
      expect(build.reload.restarted_at).to_not be_nil
    end

    it 'dispatches a build:restarted event' do
      Travis::Event.expects(:dispatch).with('build:restarted', anything)
      receive
    end

    describe 'it denormalizes to the repository' do
      %w(state duration started_at finished_at).each do |attr|
        it "sets last_build_#{attr}" do
          receive
          expect(repo.reload.send(:"last_build_#{attr}").to_s).to eql(build.reload.send(attr).to_s)
        end
      end
    end
  end

  shared_examples 'does not apply' do
    it 'does not change the build :state' do
      receive
      expect(build.reload.state).to eql(state)
    end

    it 'does not change the build `[state]ed_at` time' do
      state = [:passed, :failed, :errored].include?(self.state) ? :finished : self.state
      attr = "#{state}_ed".sub(/eed$/, 'ed')
      expect { receive }.to_not change { build.reload.send(attr) } if build.respond_to?(attr)
    end

    it 'does not change the build :state' do
      receive
      expect(build.reload.state).to eql(state)
    end

    it 'does not change the build `[state]ed_at` time' do
      attr = "#{state}_ed".sub(/eed$/, 'ed')
      expect { receive }.to_not change { build.reload.send(attr) } if build.respond_to?(attr)
    end
  end

  describe 'a :cancel event' do
    let(:event) { :cancel }

    describe 'received by a :created build' do
      let(:state) { :created }
      include_examples 'cancels the build'
    end

    describe 'received by a :queued build' do
      let(:state) { :queued }
      include_examples 'cancels the build'
    end

    describe 'received by a :received build' do
      let(:state) { :received }
      include_examples 'cancels the build'
    end

    describe 'received by a :started build' do
      let(:state) { :started }
      include_examples 'cancels the build'
    end

    describe 'received by a :passed build' do
      let(:state) { :passed }
      include_examples 'does not apply'
    end

    describe 'received by a :failed build' do
      let(:state) { :failed }
      include_examples 'does not apply'
    end

    describe 'received by a :errored build' do
      let(:state) { :errored }
      include_examples 'does not apply'
    end

    describe 'received by a :canceled build' do
      let(:state) { :canceled }
      include_examples 'does not apply'
    end
  end

  describe 'a :restart event' do
    let(:event)  { :restart }

    describe 'received by a :created build' do
      let(:state) { :created }
      include_examples 'does not apply'
    end

    describe 'received by a :queued build' do
      let(:state) { :queued }
      include_examples 'restarts the build'
    end

    describe 'received by a :received build' do
      let(:state) { :received }
      include_examples 'restarts the build'
    end

    describe 'received by a :started build' do
      let(:state) { :started }
      include_examples 'restarts the build'
    end

    describe 'received by a :passed build' do
      let(:state) { :passed }
      include_examples 'restarts the build'
    end

    describe 'received by a :failed build' do
      let(:state) { :failed }
      include_examples 'restarts the build'
    end

    describe 'received by an :errored build' do
      let(:state) { :errored }
      include_examples 'restarts the build'
    end

    describe 'received by a :canceled build' do
      let(:state) { :canceled }
      include_examples 'restarts the build'
    end
  end

  describe 'a :create event' do
    let(:event) { :create }
    let(:state) { :persisted }

    it 'sets build.state to :created' do
      receive
      expect(build.reload.state).to eql(:created)
    end

    it 'dispatches a build:created event' do
      Travis::Event.expects(:dispatch).with('build:created', anything)
      receive
    end
  end

  describe 'a :start event' do
    let(:event) { :start }

    describe 'a pull request' do
      let!(:build) { FactoryGirl.create(:build, repository: repo, state: :created, event_type: 'pull_request') }
      it 'sets the build as current build' do
        receive
        expect(repo.reload.current_build_id).to eq build.id
      end
    end

    describe 'a push build' do
      let!(:build) { FactoryGirl.create(:build, repository: repo, state: :created, event_type: 'push') }

      it 'does not set the build as current build if any newer builds exist in started of one of the finished states' do
        FactoryGirl.create(:build, repository: repo, number: 2, state: :started, event_type: 'api')
        receive
        expect(repo.reload.current_build_id).to_not eq build.id
      end
    end
  end

  describe 'a :finish event' do
    let(:event)  { :finish }

    describe 'with a :canceled state' do
      let(:state) { :canceled }

      it 'does not change its current state' do
        receive_event = build.send(:"#{event}!", { state: state })
        expect { receive_event }.to_not change { build.reload.state }
        described_class.expects(:notify).never
      end
    end
  end

  describe 'timestamps' do
    let(:job)   { FactoryGirl.create(:job, build: build) }
    let(:other) { FactoryGirl.create(:job, build: build) }
    let(:started_at) { Time.now - 6 }

    it 'a build with a matrix, starting multiple jobs' do
      job.start!(started_at: started_at, state: 'started')
      other.start!(started_at: Time.now, state: 'started')
      expect(build.reload.started_at).to eq started_at
    end

    it 'worker sending started_at for the finish event' do
      job.start!(started_at: started_at, state: 'started')
      job.finish!(started_at: Time.now - 60, finished_at: Time.now, state: 'passed')
      expect(build.reload.started_at).to eq started_at
    end
  end
end
