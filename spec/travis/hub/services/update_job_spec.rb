describe Travis::Hub::Services::UpdateJob do
  let(:state)  { :queued }
  let(:job)    { FactoryGirl.create(:job, state: state, received_at: Time.now - 10) }
  let(:params) { { event: 'start', data: { id: job.id, started_at: Time.now } } }
  subject      { described_class.new(params) }

  it 'updates the job' do
    subject.run
    expect(job.reload.state).to eql(:started)
  end

  it 'instruments #run' do
    subject.run
    expect(stdout.string).to include("Travis::Services::UpdateJob#run:completed event: start for <Job id=#{job.id}>")
  end

  describe 'with a canceled job' do
    let(:state)  { :canceled }
    let(:fanout) { Travis::Amqp::FanoutPublisher.any_instance }
    before       { fanout.stubs(:publish) }

    it 're-cancels the job in the workers' do
      fanout.expects(:publish).with(type: 'cancel_job', job_id: job.id, source: 'update_job_service')
      subject.run
    end
  end
end
