describe Travis::Addons::Handlers::Billing do
  let(:build)        { FactoryGirl.create(:build) }
  let(:job_config)   { FactoryGirl.create(:job_config, repository_id: build.repository_id) }
  let(:job)          { FactoryGirl.create(:job, owner: owner, config_id: job_config.id) }
  let(:owner)        { FactoryGirl.create(:user) }



  describe 'handle' do
    context 'when handling a job' do
      let(:handler) { described_class.new('job:finished', id: job.id) }
      let(:executions_call) do
        stub_request(:post, 'http://localhost:9292/usage/executions')
          .to_return(status: 200, body: '', headers: {})
      end

      it 'publishes to billing' do
        handler.handle

        expect(executions_call).to have_been_made
      end
    end

    context 'when handling a build' do
      let(:handler) { described_class.new('build:finished', id: job.id) }
      let(:build_users_call) do
        stub_request(:post, 'http://localhost:9292/usage/build_users')
          .to_return(status: 200, body: '', headers: {})
      end

      it 'publishes to billing' do
        handler.handle

        expect(build_users_call).to have_been_made
      end
    end
  end
end
