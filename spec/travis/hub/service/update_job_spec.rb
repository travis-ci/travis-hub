describe Travis::Hub::Service::UpdateJob do
  let(:redis) { Travis::Hub.context.redis }
  let(:amqp)  { Travis::Amqp.any_instance }
  let(:job)   { FactoryGirl.create(:job, state: state, received_at: Time.now - 10) }

  subject    { described_class.new(context, event, data) }
  before     { amqp.stubs(:fanout) }

  describe 'start event' do
    let(:state) { :queued }
    let(:event) { :start }
    let(:data)  { { id: job.id, started_at: Time.now } }

    it 'updates the job' do
      subject.run
      expect(job.reload.state).to eql(:started)
    end

    it 'instruments #run' do
      subject.run
      expect(stdout.string).to include("Travis::Hub::Service::UpdateJob#run:completed event: start for repo=travis-ci/travis-core id=#{job.id}")
    end
  end

  describe 'receive event' do
    let(:state) { :queued }
    let(:event) { :receive }
    let(:data)  { { id: job.id, received_at: Time.now } }

    it 'updates the job' do
      subject.run
      expect(job.reload.state).to eql(:received)
    end

    it 'instruments #run' do
      subject.run
      expect(stdout.string).to include("Travis::Hub::Service::UpdateJob#run:completed event: receive for repo=travis-ci/travis-core id=#{job.id}")
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

    it 'instruments #run' do
      subject.run
      expect(stdout.string).to include("Travis::Hub::Service::UpdateJob#run:completed event: cancel for repo=travis-ci/travis-core id=#{job.id}")
    end

    it 'notifies workers' do
      amqp.expects(:fanout).with('worker.commands', type: 'cancel_job', job_id: job.id, source: 'hub')
      subject.run
    end
  end

  describe 'restart event' do
    let(:state) { :passed }
    let(:event) { :restart }
    let(:data)  { { id: job.id } }

    it 'updates the job' do
      subject.run
      expect(job.reload.state).to eql(:created)
    end

    it 'instruments #run' do
      subject.run
      expect(stdout.string).to include("Travis::Hub::Service::UpdateJob#run:completed event: restart for repo=travis-ci/travis-core id=#{job.id}")
    end

    describe 'with restarts being limited' do
      let(:started) { Time.now - 7 * 3600 }
      let(:limit)   { Travis::Hub::Helper::Limit::Limit.new(redis, :restarts, job.id) }
      let(:state)   { :queued }
      before { 50.times { limit.record(started) } }
      before { subject.run }
      it { expect(job.reload.state).to eql(:errored) }
      it { expect(job.log.parts.map(&:content).join).to eq "Restarts limited: Please try restarting this job later or contact support@travis-ci.com." }
      it { expect(stdout.string).to include "Restarts limited: 50 restarts between 2010-12-31 15:02:00 UTC and #{Time.now.to_s} (max: 50, after: 21600)" }
    end
  end

  describe 'a :restart event with state: :created passed (legacy worker?)' do
    let(:state) { :started }
    let(:event) { :restart }
    let(:data)  { { id: job.id, state: :created } }

    it 'updates the job' do
      subject.run
      expect(job.reload.state).to eql(:created)
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
