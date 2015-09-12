describe Travis::Hub::Service::UpdateJob do
  let(:job)    { FactoryGirl.create(:job, state: state, received_at: Time.now - 10) }
  let(:params) { { event: event, data: data } }
  let(:amqp)   { Travis::Amqp::FanoutPublisher.any_instance }

  subject      { described_class.new(params) }
  before       { amqp.stubs(:publish) }

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
      expect(stdout.string).to include("Travis::Hub::Service::UpdateJob#run:completed event: start for <Job id=#{job.id}>")
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
      expect(stdout.string).to include("Travis::Hub::Service::UpdateJob#run:completed event: receive for <Job id=#{job.id}>")
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
      expect(stdout.string).to include("Travis::Hub::Service::UpdateJob#run:completed event: finish for <Job id=#{job.id}>")
    end
  end

  describe 'cancel event' do
    let(:state) { :created }
    let(:event) { :cancel }
    let(:data)  { { id: job.id } }

    it 'updates the job' do
      subject.run
      expect(job.reload.state).to eql(:canceled)
    end

    it 'instruments #run' do
      subject.run
      expect(stdout.string).to include("Travis::Hub::Service::UpdateJob#run:completed event: cancel for <Job id=#{job.id}>")
    end

    it 'notifies workers' do
      amqp.expects(:publish).with(type: 'cancel_job', job_id: job.id, source: 'hub')
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
      expect(stdout.string).to include("Travis::Hub::Service::UpdateJob#run:completed event: restart for <Job id=#{job.id}>")
    end
  end

  describe 'unordered messages' do
    let(:job)     { FactoryGirl.create(:job, state: :created) }
    let(:start)   { { event: 'start',   data: { id: job.id, started_at: Time.now } } }
    let(:receive) { { event: 'receive', data: { id: job.id, received_at: Time.now } } }
    let(:finish)  { { event: 'finish',  data: { id: job.id, state: 'passed', finished_at: Time.now } } }

    def recieve(msg)
      described_class.new(msg).run
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
