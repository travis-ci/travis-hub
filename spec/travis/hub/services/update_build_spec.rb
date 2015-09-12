describe Travis::Hub::Service::UpdateBuild do
  let(:build)  { FactoryGirl.create(:build, jobs: [job], state: state, received_at: Time.now - 10) }
  let(:job)    { FactoryGirl.create(:job, state: :started) }
  let(:params) { { event: event, data: { id: build.id } } }
  let(:amqp)   { Travis::Amqp::FanoutPublisher.any_instance }

  subject      { described_class.new(params) }
  before       { amqp.stubs(:publish) }

  describe 'cancel event' do
    let(:state) { :started }
    let(:event) { :cancel }

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
