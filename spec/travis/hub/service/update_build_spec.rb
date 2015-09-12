describe Travis::Hub::Service::UpdateBuild do
  let(:build)  { FactoryGirl.create(:build, jobs: [job], state: state, received_at: Time.now - 10) }
  let(:job)    { FactoryGirl.create(:job, state: state) }
  let(:params) { { event: event, data: data } }
  let(:amqp)   { Travis::Amqp::FanoutPublisher.any_instance }

  subject      { described_class.new(params) }
  before       { amqp.stubs(:publish) }

  describe 'start event' do
    let(:state) { :created }
    let(:event) { :start }
    let(:data)  { { id: build.id, started_at: Time.now } }

    it 'updates the build' do
      subject.run
      expect(build.reload.state).to eql(:started)
    end

    it 'instruments #run' do
      subject.run
      expect(stdout.string).to include("Travis::Hub::Service::UpdateBuild#run:completed event: start for <Build id=#{build.id}>")
    end
  end

  describe 'finish event' do
    let(:state) { :started }
    let(:event) { :finish }
    let(:data)  { { id: build.id, state: :passed, finished_at: Time.now } }

    it 'updates the build' do
      subject.run
      expect(build.reload.state).to eql(:passed)
    end

    it 'instruments #run' do
      subject.run
      expect(stdout.string).to include("Travis::Hub::Service::UpdateBuild#run:completed event: finish for <Build id=#{build.id}>")
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
      expect(stdout.string).to include("Travis::Hub::Service::UpdateBuild#run:completed event: cancel for <Build id=#{build.id}>")
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
      expect(stdout.string).to include("Travis::Hub::Service::UpdateBuild#run:completed event: restart for <Build id=#{build.id}>")
    end
  end
end
