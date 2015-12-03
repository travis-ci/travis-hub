describe Travis::Hub::Handler do
  let(:started_at)   { '2015-12-01T10:20:30Z' }
  let(:received_at)  { '2015-12-01T10:20:40Z' }
  let(:finished_at)  { '2015-12-01T10:20:50Z' }

  # let(:update_build) { Travis::Hub::Service::UpdateBuild }
  # let(:update_job)   { Travis::Hub::Service::UpdateJob }
  # let(:service)      { stub('service', run: nil) }

  let!(:build)       { FactoryGirl.create(:build, id: 1, state: :created, jobs: [job]) }
  let(:job)          { FactoryGirl.create(:job, id: 1, state: :created) }

  subject            { described_class.new(context, event, payload) }
  before             { subject.run }

  describe 'a job:finish event' do
    let(:event)      { 'job:finish' }
    let(:payload)    { { id: 1, state: 'passed', started_at: started_at, received_at: received_at, finished_at: finished_at } }

    it { expect(job.reload.state).to eql(:passed) }
    it { expect(job.reload.started_at).to eql(Time.parse(started_at)) }
    it { expect(job.reload.received_at).to eql(Time.parse(received_at)) }
    it { expect(job.reload.finished_at).to eql(Time.parse(finished_at)) }

    describe 'given false timestamps' do
      let(:started_at)  { '0001-01-01T00:00:00Z' }

      it { expect { job.reload.started_at }.to_not raise_error }
      it { expect(job.reload.started_at).to be_nil }
      it { expect(job.reload.duration).to eql(nil) }
    end
  end

  def except(hash, *keys)
    hash.reject { |key, value| keys.include?(key) }
  end
end
