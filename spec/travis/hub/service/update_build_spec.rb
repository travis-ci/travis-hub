[true, false].each do |logs_api_enabled|
  describe Travis::Hub::Service::UpdateBuild, logs_api_enabled: logs_api_enabled do
    let(:now)   { Time.now }
    let(:build) { FactoryGirl.create(:build, jobs: [job], state: state, received_at: now - 10) }
    let(:job)   { FactoryGirl.create(:job, state: state) }
    let(:amqp)  { Travis::Amqp.any_instance }

    subject     { described_class.new(context, event, data) }
    before      { amqp.stubs(:fanout) }

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

      it 'instruments #run' do
        subject.run
        expect(stdout.string).to include("Travis::Hub::Service::UpdateBuild#run:completed event: cancel for repo=travis-ci/travis-core id=#{build.id}")
      end

      it 'notifies workers' do
        amqp.expects(:fanout).with('worker.commands', type: 'cancel_job', job_id: job.id, source: 'hub')
        subject.run
      end
    end

    describe 'cancel event (gator, auto cancel)' do
      let(:state) { :created }
      let(:event) { :cancel }
      let(:meta)  { { 'event' => 'pull_request', 'number' => '2', 'branch' => 'master', 'pull_request_number' => '1' } }
      let(:data)  { { id: build.id, meta: meta } }
      let(:now) { Time.now }

      before do
        if context.config.logs_api.enabled?
          subject.send(:logs_api).expects(:append_log_part)
        end
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

      it 'adds an additional log line' do
        if context.config.logs_api.enabled?
          skip('log persistence not verified when logs_api.enabled?')
        end
        subject.run
        expect(job.log.parts.last.content).to include('This job was cancelled because the "Auto Cancellation" feature is currently enabled, and a more recent build (#2) for pull request #1 came in while this job was waiting to be processed.')
      end
    end


    describe 'restart event' do
      let(:state) { :passed }
      let(:event) { :restart }
      let(:data)  { { id: build.id } }

      before do
        if context.config.logs_api.enabled?
          Job.any_instance.expects(:clear_log_via_http)
        end
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
end
