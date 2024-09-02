describe Travis::Addons::Handlers::JobConfig do
  let(:build)        { FactoryBot.create(:build) }
  let(:job_config)   { FactoryBot.create(:job_config, repository_id: build.repository_id) }
  let(:job)          { FactoryBot.create(:job, owner:, config_id: job_config.id) }
  let(:owner)        { FactoryBot.create(:user) }

  describe 'handle' do
    let(:handler) { described_class.new(event_name, id: job.id , **params) }

    let(:event_name) { 'job:started' }
    context 'when vm_size is provided' do
      let(:params) { {worker_meta: [ { vm_size: '2x-large' } ]} }

      it 'updates the job vm_size' do
        handler.handle
        expect(Job.find(job.id).state).to eq(:created)
        expect(Job.find(job.id).vm_size).to eq('2x-large')
      end
    end

    context 'when vm_size is not provided' do
      let(:params) { {worker_meta: [ { } ]} }

      it 'updates the job vm_size' do
        handler.handle
        expect(Job.find(job.id).state).to eq(:created)
        expect(Job.find(job.id).vm_size).to be_nil
      end
    end
  end
end
