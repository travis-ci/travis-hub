describe Travis::Hub::Service::UpdateJob do
  let(:redis)       { Travis::Hub.context.redis }
  let(:amqp)        { Travis::Amqp.any_instance }
  let(:job)         { FactoryGirl.create(:job, state: state, queued_at: queued_at, received_at: received_at) }
  let(:queued_at)   { now - 20 }
  let(:received_at) { now - 10 }
  let(:now)         { Time.now.utc }

  subject     { described_class.new(context, event, data) }

  before do
    amqp.stubs(:fanout)
    stub_request(:delete, %r{https://job-board\.travis-ci\.com/jobs/\d+\?source=hub})
      .to_return(status: 204)
  end

  describe 'receive event' do
    let(:state) { :queued }
    let(:event) { :receive }
    let(:data)  { { id: job.id, received_at: now } }

    it 'updates the job' do
      subject.run
      expect(job.reload.state).to eql(:received)
    end

    it 'instruments #run' do
      subject.run
      expect(stdout.string).to include("Travis::Hub::Service::UpdateJob#run:completed event: receive for repo=travis-ci/travis-core id=#{job.id}")
    end

    describe 'with received_at < queued_at (Worker living in the past' do
      let(:queued_at) { now + 10 }

      it 'sets received_at to queued_at' do
        subject.run
        expect(job.reload.received_at).to eq queued_at
      end
    end

    describe 'when the job has been canceled meanwhile' do
      let(:state) { :canceled }

      it 'does not update the job state' do
        subject.run
        expect(job.reload.state).to eql(:canceled)
      end

      it 'broadcasts a cancel message' do
        amqp.expects(:fanout).with('worker.commands', type: 'cancel_job', job_id: job.id, source: 'hub')
        subject.run
      end
    end
  end

  describe 'start event' do
    let(:state) { :queued }
    let(:event) { :start }
    let(:data)  { { id: job.id, started_at: now } }

    it 'updates the job' do
      subject.run
      expect(job.reload.state).to eql(:started)
    end

    it 'instruments #run' do
      subject.run
      expect(stdout.string).to include("Travis::Hub::Service::UpdateJob#run:completed event: start for repo=travis-ci/travis-core id=#{job.id}")
    end

    describe 'when the job has been canceled meanwhile' do
      let(:state) { :canceled }

      it 'does not update the job state' do
        subject.run
        expect(job.reload.state).to eql(:canceled)
      end

      it 'broadcasts a cancel message' do
        amqp.expects(:fanout).with('worker.commands', type: 'cancel_job', job_id: job.id, source: 'hub')
        subject.run
      end
    end
  end

  describe 'finish event' do
    let(:state) { :queued }
    let(:event) { :finish }
    let(:data)  { { id: job.id, state: :passed, finished_at: Time.now } }

    it 'updates the job' do
      subject.run
      expect(job.reload.state).to eql(:passed)
    end

    it 'instruments #run' do
      subject.run
      expect(stdout.string).to include("Travis::Hub::Service::UpdateJob#run:completed event: finish for repo=travis-ci/travis-core id=#{job.id}")
    end
  end

  describe 'cancel event' do
    let(:state) { :created }
    let(:event) { :cancel }
    let(:data)  { { id: job.id } }
    let(:now) { Time.now }

    it 'updates the job' do
      subject.run
      expect(job.reload.state).to eql(:canceled)
      expect(job.reload.canceled_at).to eql(now)
    end

    it 'notifies workers' do
      amqp.expects(:fanout).with('worker.commands', type: 'cancel_job', job_id: job.id, source: 'hub')
      subject.run
    end

    it 'instruments #run' do
      subject.run
      expect(stdout.string).to include("Travis::Hub::Service::UpdateJob#run:completed event: cancel for repo=travis-ci/travis-core id=#{job.id}")
    end
  end

  describe 'restart event' do
    let(:state) { :passed }
    let(:event) { :restart }
    let(:data)  { { id: job.id } }

    it 'resets the job' do
      Job.any_instance.expects(:clear_log)
      subject.run
      expect(job.reload.state).to eql(:created)
    end

    it 'instruments #run' do
      Job.any_instance.expects(:clear_log)
      subject.run
      expect(stdout.string).to include("Travis::Hub::Service::UpdateJob#run:completed event: restart for repo=travis-ci/travis-core id=#{job.id}")
    end
  end

  describe 'a :restart event with state: :created passed (legacy worker?)' do
    let(:state) { :started }
    let(:event) { :restart }
    let(:data)  { { id: job.id, state: :created } }

    it 'updates the job' do
      Job.any_instance.expects(:clear_log)
      subject.run
      expect(job.reload.state).to eql(:created)
    end
  end

  describe 'reset event' do
    let(:state) { :started }
    let(:event) { :reset }
    let(:data)  { { id: job.id } }

    it 'resets the job' do
      Job.any_instance.expects(:clear_log)
      subject.run
      expect(job.reload.state).to eql(:created)
    end

    it 'instruments #run' do
      Job.any_instance.expects(:clear_log)
      subject.run
      expect(stdout.string).to include("Travis::Hub::Service::UpdateJob#run:completed event: reset for repo=travis-ci/travis-core id=#{job.id}")
    end

    describe 'with resets being limited' do
      let(:url)     { 'http://logs.travis-ci.org/' }
      let(:started) { Time.now - 7 * 3600 }
      let(:limit)   { Travis::Hub::Limit.new(redis, :resets, job.id) }
      let(:state)   { :queued }

      before { context.config[:logs_api] = { url: url, token: '1234' } }
      before { stub_request(:put, "http://logs.travis-ci.org/logs/#{job.id}?source=hub") }
      before { 50.times { limit.record(started) } }

      describe 'sets the job to :errored' do
        before { subject.run }
        it { expect(job.reload.state).to eql(:errored) }
      end

      describe 'logs a message' do
        before { subject.run }
        it { expect(stdout.string).to include "Resets limited: 50 resets between 2010-12-31 15:02:00 UTC and #{Time.now.to_s} (max: 50, after: 21600)" }
      end
    end
  end

  describe 'unordered messages' do
    let(:job)     { FactoryGirl.create(:job, state: :created) }
    let(:start)   { [:start,   { id: job.id, started_at: Time.now }] }
    let(:receive) { [:receive, { id: job.id, received_at: Time.now }] }
    let(:finish)  { [:finish,  { id: job.id, state: 'passed', finished_at: Time.now }] }

    def recieve(msg)
      described_class.new(context, *msg).run
    end

    it 'works (1)' do
      recieve(finish)
      recieve(receive)
      recieve(start)
      expect(job.reload.state).to eql :passed
    end

    it 'works (2)' do
      recieve(start)
      recieve(receive)
      recieve(finish)
      expect(job.reload.state).to eql :passed
    end
  end
end
