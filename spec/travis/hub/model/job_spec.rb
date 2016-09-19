describe Job do
  let(:params) { {} }
  let(:repo)   { FactoryGirl.create(:repository) }
  let(:build)  { FactoryGirl.create(:build, repository: repo, state: [:received, :queued].include?(state) ? :created : state) }
  let(:job)    { FactoryGirl.create(:job, repository: repo, build: build, state: state) }
  let(:now)    { Time.now }
  before       { Travis::Event.stubs(:dispatch) }

  def receive
    job.send(:"#{event}!", params)
  end

  shared_examples 'sets the job to :received' do
    it 'returns true' do
      expect(receive).to be_truthy
    end

    it 'sets :state to :received' do
      receive
      expect(job.reload.state).to eql(:received)
    end

    it 'sets :received_at' do
      receive
      expect(job.reload.received_at).to eql(now)
    end

    it 'dispatches a job:received event' do
      Travis::Event.expects(:dispatch).with('job:received', id: job.id)
      receive
    end
  end

  shared_examples 'sets the job to :started' do
    it 'returns true' do
      expect(receive).to be_truthy
    end

    it 'sets :state to :started' do
      receive
      expect(job.reload.state).to eql(:started)
    end

    it 'sets :started_at' do
      receive
      expect(job.reload.started_at).to eql(now)
    end

    it 'dispatches a job:started event' do
      Travis::Event.expects(:dispatch).with('job:started', id: job.id)
      receive
    end

    describe 'propagates to the build' do
      it 'sets :state to :started' do
        receive
        expect(job.build.reload.state).to eql(:started)
      end

      it 'sets :finished_at' do
        receive
        expect(job.build.reload.started_at).to eql(now)
      end
    end

    describe 'it denormalizes to the repository' do
      %w(id number state duration started_at finished_at).each do |attr|
        it "sets last_build_#{attr}" do
          receive
          expect(repo.reload.send(:"last_build_#{attr}").to_s).to eql(build.reload.send(attr).to_s)
        end
      end
    end
  end

  shared_examples 'sets the job to :passed' do
    it 'returns true' do
      expect(receive).to be_truthy
    end

    it 'sets :state to :passed' do
      receive
      expect(job.reload.state).to eql(:passed)
    end

    it 'sets :finished_at' do
      receive
      expect(job.reload.finished_at).to eql(now)
    end

    it 'dispatches a job:finished event' do
      Travis::Event.expects(:dispatch).with('job:finished', id: job.id)
      receive
    end

    describe 'propagates to the build' do
      describe 'with all other jobs being finished' do
        it 'sets :state to :passed' do
          receive
          expect(job.build.reload.state).to eql(:passed)
        end

        it 'sets :finished_at' do
          receive
          expect(job.build.reload.finished_at).to eql(now)
        end
      end

      describe 'with other jobs being pending' do
        before do
          FactoryGirl.create(:job, build: build, state: :started)
        end

        it 'does not set :state to :passed' do
          receive
          expect(job.build.reload.state).to_not eql(:passed)
        end

        it 'does not set :finished_at' do
          receive
          expect(job.build.reload.finished_at).to be_nil
        end
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

  shared_examples 'cancels the job' do
    it 'returns true' do
      expect(receive).to be_truthy
    end

    it 'sets :state to :canceled' do
      receive
      expect(job.reload.state).to eql(:canceled)
    end

    it 'sets :canceled_at' do
      receive
      expect(job.reload.canceled_at).to eql(now)
    end

    it 'sets :finished_at' do
      receive
      expect(job.reload.finished_at).to eql(now)
    end

    it 'dispatches a job:canceled event' do
      Travis::Event.expects(:dispatch).with('job:canceled', id: job.id)
      receive
    end

    describe 'with all other jobs being finished' do
      it 'sets the build to :canceled' do
        receive
        expect(job.build.reload.state).to eql(:canceled)
      end
    end

    describe 'with other jobs being pending' do
      before do
        FactoryGirl.create(:job, build: build, state: :started)
      end

      it 'does not set the build to :canceled' do
        receive
        expect(job.build.reload.state).to_not eql(:canceled)
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

  shared_examples 'resets the job' do
    it 'returns true' do
      expect(receive).to be_truthy
    end

    it 'sets :state to :created' do
      receive
      expect(job.reload.state).to eql(:created)
    end

    it 'resets :queued_at' do
      receive
      expect(job.reload.queued_at).to be_nil
    end

    it 'resets :received_at' do
      receive
      expect(job.reload.received_at).to be_nil
    end

    it 'resets :started_at' do
      receive
      expect(job.reload.started_at).to be_nil
    end

    it 'resets :finished_at' do
      receive
      expect(job.reload.finished_at).to be_nil
    end

    it 'resets :canceled_at' do
      receive
      expect(job.reload.canceled_at).to be_nil
    end

    it 'dispatches a job:restarted event' do
      Travis::Event.expects(:dispatch).with('job:restarted', id: job.id)
      receive
    end

    describe 'propagates to the build' do
      it 'sets :state to :created' do
        receive
        expect(job.build.reload.state).to eql(:created)
      end

      it 'resets :duration' do
        receive
        expect(job.build.reload.duration).to be_nil
      end

      it 'resets :started_at' do
        receive
        expect(job.build.reload.started_at).to be_nil
      end

      it 'resets :finished_at' do
        receive
        expect(job.build.reload.finished_at).to be_nil
      end

      it 'clears log' do
        receive
        expect(job.log.reload.content).to be_empty
        expect(job.log.reload.archive_verified).to be_nil
        expect(job.log.reload.removed_by).to be_nil
        expect(job.log.reload.removed_at).to be_nil
      end

      it 'does not reset other jobs on the matrix' do
        other = FactoryGirl.create(:job, build: job.build, state: :passed)
        receive
        expect(other.reload.state).to eql(:passed)
      end
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
    it 'does not change the job :state' do
      receive
      expect(job.reload.state).to eql(state)
    end

    it 'does not change the job `[state]ed_at` time' do
      attr = "#{state}_ed".sub(/eed$/, 'ed')
      expect { receive }.to_not change { job.reload.send(attr) } if job.respond_to?(attr)
    end

    it 'does not change the build :state' do
      receive
      expect(job.reload.state).to eql(state)
    end

    it 'does not change the build `[state]ed_at` time' do
      attr = "#{state}_ed".sub(/eed$/, 'ed')
      expect { receive }.to_not change { build.reload.send(attr) } if build.respond_to?(attr)
    end
  end

  describe 'a :receive event' do
    let(:event)  { :receive }
    let(:params) { { state: 'received', received_at: now.to_s } }

    describe 'received by a :created job' do
      let(:state) { :created }
      include_examples 'sets the job to :received'
    end

    describe 'received by a :queued job' do
      let(:state) { :queued }
      include_examples 'sets the job to :received'
    end

    describe 'received by a :received job' do
      let(:state) { :received }
      include_examples 'does not apply'
    end

    describe 'received by a :started job' do
      let(:state) { :started }
      include_examples 'does not apply'
    end

    describe 'received by a :passed job' do
      let(:state) { :passed }
      include_examples 'does not apply'
    end

    describe 'received by a :failed job' do
      let(:state) { :failed }
      include_examples 'does not apply'
    end

    describe 'received by an :errored job' do
      let(:state) { :errored }
      include_examples 'does not apply'
    end

    describe 'received by a :canceled job' do
      let(:state) { :canceled }
      include_examples 'does not apply'
    end
  end

  describe 'a :start event' do
    let(:event)  { :start }
    let(:params) { { state: 'started', started_at: now.to_s } }

    describe 'received by a :created job' do
      let(:state) { :created }
      include_examples 'sets the job to :started'
    end

    describe 'received by a :queued job' do
      let(:state) { :queued }
      include_examples 'sets the job to :started'
    end

    describe 'received by a :received job' do
      let(:state) { :received }
      include_examples 'sets the job to :started'
    end

    describe 'received by a :started job' do
      let(:state) { :started }
      include_examples 'does not apply'
    end

    describe 'received by a :passed job' do
      let(:state) { :passed }
      include_examples 'does not apply'
    end

    describe 'received by a :failed job' do
      let(:state) { :failed }
      include_examples 'does not apply'
    end

    describe 'received by an :errored job' do
      let(:state) { :errored }
      include_examples 'does not apply'
    end

    describe 'received by a :canceled job' do
      let(:state) { :canceled }
      include_examples 'does not apply'
    end
  end

  describe 'a :finish event' do
    let(:event)  { :finish }
    let(:params) { { state: 'passed', finished_at: now.to_s } }

    describe 'received by a :created job' do
      let(:state) { :created }
      include_examples 'sets the job to :passed'
    end

    describe 'received by a :queued job' do
      let(:state) { :queued }
      include_examples 'sets the job to :passed'
    end

    describe 'received by a :received job' do
      let(:state) { :received }
      include_examples 'sets the job to :passed'
    end

    describe 'received by a :started job' do
      let(:state) { :started }
      include_examples 'sets the job to :passed'
    end

    describe 'received by a :passed job' do
      let(:state) { :passed }
      include_examples 'does not apply'
    end

    describe 'received by a :failed job' do
      let(:state) { :failed }
      include_examples 'does not apply'
    end

    describe 'received by an :errored job' do
      let(:state) { :errored }
      include_examples 'does not apply'
    end

    describe 'received by a :canceled job' do
      let(:state) { :canceled }
      include_examples 'does not apply'
    end
  end

  [:reset, :restart].each do |event|
    describe "a #{event} event" do
      let(:event)  { event }

      describe 'received by a :created job' do
        let(:state) { :created }
        include_examples 'does not apply'
      end

      describe 'received by a :queued job' do
        let(:state) { :queued }
        include_examples 'resets the job'
      end

      describe 'received by a :received job' do
        let(:state) { :received }
        include_examples 'resets the job'
      end

      describe 'received by a :started job' do
        let(:state) { :started }
        include_examples 'resets the job'
      end

      describe 'received by a :passed job' do
        let(:state) { :passed }
        include_examples 'resets the job'
      end

      describe 'received by a :failed job' do
        let(:state) { :failed }
        include_examples 'resets the job'
      end

      describe 'received by an :errored job' do
        let(:state) { :errored }
        include_examples 'resets the job'
      end

      describe 'received by a :canceled job' do
        let(:state) { :canceled }
        include_examples 'resets the job'
      end
    end
  end

  describe 'a :cancel event' do
    let(:event)  { :cancel }

    describe 'received by a :created job' do
      let(:state) { :created }
      include_examples 'cancels the job'
    end

    describe 'received by a :queued job' do
      let(:state) { :queued }
      include_examples 'cancels the job'
    end

    describe 'received by a :received job' do
      let(:state) { :received }
      include_examples 'cancels the job'
    end

    describe 'received by a :started job' do
      let(:state) { :started }
      include_examples 'cancels the job'
    end

    describe 'received by a :passed job' do
      let(:state) { :passed }
      include_examples 'does not apply'
    end

    describe 'received by a :failed job' do
      let(:state) { :failed }
      include_examples 'does not apply'
    end

    describe 'received by an :errored job' do
      let(:state) { :errored }
      include_examples 'does not apply'
    end

    describe 'received by a :canceled job' do
      let(:state) { :canceled }
      include_examples 'does not apply'
    end
  end
end
