describe Build do
  let(:params) { {} }
  let(:repo)   { FactoryGirl.create(:repository) }
  let(:build)  { FactoryGirl.create(:build, repository: repo, state: state) }
  let(:now)    { Time.now }
  before       { Travis::Event.stubs(:dispatch) }

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
      Travis::Event.expects(:dispatch).with('build:canceled', id: build.id)
      receive
    end

    describe 'with all other jobs being finished' do
      it 'sets the build to :canceled' do
        receive
        expect(build.reload.state).to eql(:canceled)
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

    it 'dispatches a build:restarted event' do
      Travis::Event.expects(:dispatch).with('build:restarted', id: build.id)
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
      include_examples 'does not apply'
    end

    describe 'received by a :started build' do
      let(:state) { :started }
      include_examples 'does not apply'
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

  # describe 'a build with a matrix, starting jobs' do
  #   let(:state) { :created }

  #   it 'propagates to the build only once' do
  #     FactoryGirl.create(:job, build: build)
  #     FactoryGirl.create(:job, build: build)
  #     build.jobs.each { |job| job.start!(started_at: Time.now) }
  #     build.reload.state
  #   end
  # end
end
