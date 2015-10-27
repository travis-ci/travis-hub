describe Travis::Hub::Service::UpdateBuild do
  let(:now)   { Time.now }
  let(:build) { FactoryGirl.create(:build, jobs: [job], state: state, received_at: now - 10) }
  let(:job)   { FactoryGirl.create(:job, state: state) }
  let(:amqp)  { Travis::Amqp::FanoutPublisher.any_instance }

  subject     { described_class.new(context, event, data) }
  before      { amqp.stubs(:publish) }

  describe 'start event' do
    let(:state) { :created }
    let(:event) { :start }
    let(:data)  { { id: build.id, started_at: now } }

    it 'updates the build' do
      subject.run
      expect(build.reload.state).to eql(:started)
    end

    it 'instruments #run' do
      subject.run
      expect(stdout.string).to include("Travis::Hub::Service::UpdateBuild#run:completed event: start for repo=travis-ci/travis-core id=#{build.id}")
    end
  end

  describe 'finish event' do
    before { subject.run }

    describe 'when the build is :started' do
      let(:state) { :started }
      let(:event) { :finish }
      let(:data)  { { id: build.id, state: :passed, finished_at: now } }

      it 'updates the build' do
        expect(build.reload.state).to eql(:passed)
      end

      it 'instruments #run' do
        expect(stdout.string).to include("Travis::Hub::Service::UpdateBuild#run:completed event: finish for repo=travis-ci/travis-core id=#{build.id}")
      end
    end

    describe 'when the build is :errored (Gatekeeper wants to send messages like this)' do
      let(:state) { :errored }
      let(:event) { :finish }
      let(:data)  { { id: build.id, state: :errored, started_at: now, finished_at: now } }

      it 'state is :errored' do
        expect(build.reload.state).to eql(:errored)
      end

      it 'sets :started_at' do
        expect(build.reload.started_at).to eql(now)
      end

      it 'sets :finished_at' do
        expect(build.reload.finished_at).to eql(now)
      end

      it 'instruments #run' do
        expect(stdout.string).to include("Travis::Hub::Service::UpdateBuild#run:completed event: finish for repo=travis-ci/travis-core id=#{build.id}")
      end
    end
  end

  describe 'cancel event' do
    let(:state) { :started }
    let(:event) { :cancel }
    let(:data)  { { id: build.id } }

    it 'updates the build' do
      subject.run
      expect(build.reload.state).to eql(:canceled)
    end

    it 'updates the job' do
      subject.run
      expect(job.reload.state).to eql(:canceled)
    end

    it 'instruments #run' do
      subject.run
      expect(stdout.string).to include("Travis::Hub::Service::UpdateBuild#run:completed event: cancel for repo=travis-ci/travis-core id=#{build.id}")
    end

    it 'notifies workers' do
      amqp.expects(:publish).with(type: 'cancel_job', job_id: job.id, source: 'hub')
      subject.run
    end
  end

  describe 'restart event' do
    let(:state) { :passed }
    let(:event) { :restart }
    let(:data)  { { id: build.id } }

    it 'updates the build' do
      subject.run
      expect(build.reload.state).to eql(:created)
    end

    it 'instruments #run' do
      subject.run
      expect(stdout.string).to include("Travis::Hub::Service::UpdateBuild#run:completed event: restart for repo=travis-ci/travis-core id=#{build.id}")
    end
  end
end
