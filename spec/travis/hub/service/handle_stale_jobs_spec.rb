describe Travis::Hub::Service::HandleStaleJobs do
  let(:now)         { Time.now }
  let!(:job_old)    { FactoryGirl.create(:job, state: state, updated_at: now - 6 * 3600 - 10 ) }
  let!(:job_new)    { FactoryGirl.create(:job, state: state, updated_at: now) }

  subject           { described_class.new(context) }

  describe 'jobs with the state queued' do
    let(:state) { :queued }

    it 'sets old jobs to errored' do
      subject.run
      expect(job_old.reload.state).to eql(:errored)
    end

    it 'ignores new jobs' do
      subject.run
      expect(job_new.reload.state).to eql(:queued)
    end
  end

  describe 'old jobs with state finished' do
    let(:state) { :finished }

    it 'ignores already finished old jobs' do
      subject.run
      expect(job_old.reload.state).to eql(:finished)
    end
   end

end
