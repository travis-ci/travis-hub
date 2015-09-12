describe Travis::Hub::Services::UpdateBuild do
  let(:build)  { FactoryGirl.create(:build, state: state, received_at: Time.now - 10) }
  let(:params) { { event: event, data: { id: build.id } } }
  subject      { described_class.new(params) }

  describe 'cancel event' do
    let(:state) { :created }
    let(:event) { :cancel }

    it 'updates the build' do
      subject.run
      expect(build.reload.state).to eql(:canceled)
    end

    it 'instruments #run' do
      subject.run
      expect(stdout.string).to include("Travis::Hub::Services::UpdateBuild#run:completed event: cancel for <Build id=#{build.id}>")
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
      expect(stdout.string).to include("Travis::Hub::Services::UpdateBuild#run:completed event: restart for <Build id=#{build.id}>")
    end
  end

  # describe 'with a canceled build' do
  #   let(:state)  { :canceled }
  #   let(:fanout) { Travis::Amqp::FanoutPublisher.any_instance }
  #   before       { fanout.stubs(:publish) }

  #   it 're-cancels the build in the workers' do
  #     fanout.expects(:publish).with(type: 'cancel_job', job_id: build.id, source: 'update_job_service')
  #     subject.run
  #   end
  # end
end
