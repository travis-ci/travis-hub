describe Travis::Hub::Service::HandleStaleJobs do
  subject           { described_class.new(context) }

  let(:now)         { Time.now }
  let!(:job_old)    { FactoryBot.create(:job, state:) }
  let!(:job_new)    { FactoryBot.create(:job, state:) }

  before do
    # we're using triggers to automatically set updated_at
    # so if we want to force a give updated at we need to disable the trigger
    ActiveRecord::Base.connection.execute('ALTER TABLE jobs DISABLE TRIGGER set_updated_at_on_jobs;')
    job_old.update(updated_at: now - 6 * 3600 - 10)
    job_new.update(updated_at: now)
    ActiveRecord::Base.connection.execute('ALTER TABLE jobs ENABLE TRIGGER set_updated_at_on_jobs;')
  end

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
