describe Travis::Hub::Service::UpdateBuild do
  let(:now)   { Time.now }
  let(:build) { FactoryGirl.create(:build, { jobs: [job], received_at: now - 10 }.merge(state ? { state: state } : {})) }
  let(:job)   { FactoryGirl.create(:job, state ? { state: state } : {}) }
  let(:amqp)  { Travis::Amqp.any_instance }
  let(:events)  { Travis::Event }

  subject     { described_class.new(context, event, data) }
  before      { amqp.stubs(:fanout) }
  before      { context.metrics.stubs(:meter) }
  before      { events.stubs(:dispatch) }
  before do
    stub_request(:delete, %r{https://job-board\.travis-ci\.com/jobs/\d+\?source=hub})
      .to_return(status: 204)
  end

  describe 'create event' do
    # let(:state) { :create }
    let(:state) { nil }
    let(:event) { :create }
    let(:data)  { { id: build.id, started_at: now } }

    before { build.reload.update_attributes!(state: nil) }

    it 'updates the build state' do
      subject.run
      expect(build.reload.state).to eql(:created)
    end

    it 'updates the job states' do
      subject.run
      expect(build.reload.jobs.map(&:state)).to eq [:created]
    end

    it 'updates the job queueable flags' do
      subject.run
      expect(build.reload.jobs.map { |job| !!job.queueable }).to eq [true]
    end

    it 'dispatches a build:created event' do
      Travis::Event.expects(:dispatch).with('build:created', anything)
      subject.run
    end

    it 'dispatches job:created events' do
      Travis::Event.expects(:dispatch).with('job:created', anything)
      subject.run
    end

    it 'instruments #run' do
      subject.run
      expect(stdout.string).to include("Travis::Hub::Service::UpdateBuild#run:completed event: create for repo=travis-ci/travis-core id=#{build.id}")
    end
  end

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

  describe 'cancel event (api, manual)' do
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

    it 'sets :finished_at' do
      subject.run
      expect(build.reload.finished_at).to eql(now)
    end

    it 'sets :canceled_at' do
      subject.run
      expect(build.reload.canceled_at).to eql(now)
    end

    it 'notifies workers' do
      amqp.expects(:fanout).with('worker.commands', type: 'cancel_job', job_id: job.id, source: 'hub')
      subject.run
    end

    it 'instruments #run' do
      subject.run
      expect(stdout.string).to include("Travis::Hub::Service::UpdateBuild#run:completed event: cancel for repo=travis-ci/travis-core id=#{build.id}")
    end
  end

  describe 'cancel event (gator, auto cancel)' do
    let(:state) { :created }
    let(:event) { :cancel }
    let(:meta)  { { 'auto' => true, 'event' => 'pull_request', 'number' => '2', 'branch' => 'master', 'pull_request_number' => '1' } }
    let(:data)  { { id: build.id, meta: meta } }
    let(:now) { Time.now }

    before do
      subject.send(:logs_api).expects(:append_log_part)
    end

    it 'updates the job' do
      subject.run
      expect(job.reload.state).to eql(:canceled)
      expect(job.reload.canceled_at).to eql(now)
    end

    it 'instruments #run' do
      subject.run
      expect(stdout.string).to include("Travis::Hub::Service::UpdateBuild#run:completed event: cancel for repo=travis-ci/travis-core id=#{build.id}")
    end

    it 'notifies workers' do
      amqp.expects(:fanout).with('worker.commands', type: 'cancel_job', job_id: job.id, source: 'hub')
      subject.run
    end

    it 'meters the event' do
      context.metrics.expects(:meter).with('hub.job.auto_cancel')
      subject.run
    end
  end

  # cancel jobs from custom build request, ie: event: :api
  describe 'cancel event (gator, api cancel)' do
    let(:state) { :created }
    let(:event) { :cancel }
    let(:meta)  { { 'auto' => true, 'event' => 'api', 'number' => '2', 'branch' => 'master', 'pull_request_number' => nil } }
    let(:data)  { { id: build.id, meta: meta } }
    let(:now) { Time.now }

    before do
      subject.send(:logs_api).expects(:append_log_part)
    end

    it 'updates the job' do
      subject.run
      expect(job.reload.state).to eql(:canceled)
      expect(job.reload.canceled_at).to eql(now)
    end
  end

  describe 'restart event' do
    let(:state) { :passed }
    let(:event) { :restart }
    let(:data)  { { id: build.id } }

    before do
      Job.any_instance.expects(:clear_log)
    end

    it 'updates the build' do
      subject.run
      expect(build.reload.state).to eql(:created)
    end

    it 'instruments #run' do
      subject.run
      expect(stdout.string).to include(
        'Travis::Hub::Service::UpdateBuild#run:completed event: ' \
        "restart for repo=travis-ci/travis-core id=#{build.id}"
      )
    end
  end
end
