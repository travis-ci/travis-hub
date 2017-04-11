describe Travis::Hub::Handler do
  let(:queued_at)    { '2015-12-01T10:20:20Z' }
  let(:received_at)  { '2015-12-01T10:20:30Z' }
  let(:started_at)   { '2015-12-01T10:20:40Z' }
  let(:finished_at)  { '2015-12-01T10:20:50Z' }

  let!(:build)       { FactoryGirl.create(:build, id: 1, state: :created, jobs: [job]) }
  let(:job)          { FactoryGirl.create(:job, id: 1, state: :created, owner: owner) }
  let(:owner)        { FactoryGirl.create(:user) }

  subject            { described_class.new(context, event, payload) }
  before             { subject.run }

  describe 'a job:finish event' do
    let(:event)      { 'job:finish' }
    let(:payload)    { { id: 1, state: 'passed', queued_at: queued_at, received_at: received_at, started_at: started_at, finished_at: finished_at } }

    it { expect(job.reload.state).to eql(:passed) }
    it { expect(job.reload.started_at).to eql(Time.parse(started_at)) }
    it { expect(job.reload.received_at).to eql(Time.parse(received_at)) }
    it { expect(job.reload.finished_at).to eql(Time.parse(finished_at)) }

    describe 'given false timestamps' do
      let(:started_at)  { '0001-01-01T00:00:00Z' }
      let(:received_at) { '0001-01-01T00:00:00Z' }

      it { expect { job.reload.started_at }.to_not raise_error }
      it { expect(job.reload.started_at).to be_nil }
      it { expect(job.reload.duration).to eql(nil) }
    end

    describe 'given received_at < queued_at (Worker lives in the past)' do
      let(:received_at) { '2015-12-01T10:20:10Z' }

      it { expect(job.reload.received_at).to eq job.reload.queued_at }
    end
  end

  def except(hash, *keys)
    hash.reject { |key, value| keys.include?(key) }
  end
end
