describe Travis::Addons::Handlers::Merge do
  let(:repo)    { FactoryBot.create(:repository, migration_status: 'migrated', migrated_at: Time.now) }
  let(:job)     { FactoryBot.create(:job, state: :created, repository: repo) }
  let(:build)   { FactoryBot.create(:build, state: :created, repository: repo) }
  let(:handler) { described_class.new('build:finished', id: build.id) }
  let(:cache)   { described_class.states_cache }

  before do
    Travis::Event.setup([:merge])
    ENV['MERGE_API_TOKEN'] = '1234'
    stub_request(:any, /.*/)
  end

  def notifies(event, args)
    described_class.expects(:notify)
    Travis::Event.dispatch(event, args)
  end

  describe 'subscription' do
    it { notifies('job:created',  id: job.id) }
    it { notifies('job:received', id: job.id) }
    it { notifies('job:started',  id: job.id) }
    it { notifies('job:finished', id: job.id) }
    it { notifies('job:canceled', id: job.id) }
    it { notifies('job:errored',  id: job.id) }
    it { notifies('build:created', id: build.id) }
    it { notifies('build:started', id: build.id) }
    it { notifies('build:finished', id: build.id) }
  end

  describe 'a build event' do
    before { Travis::Event.dispatch('build:finished', id: build.id) }

    it 'sends a build import request to merge' do
      assert_requested :post, "https://travis-merge-pipe-staging.herokuapp.com/api/build/#{build.id}/import"
    end

    it 'logs' do
      expect(stdout.string).to include "Merge#notify:completed Notifying merge to import build id=#{build.id}"
    end
  end

  describe 'a build event' do
    before { Travis::Event.dispatch('job:started', id: job.id) }

    it 'sends a job import request to merge' do
      assert_requested :post, "https://travis-merge-pipe-staging.herokuapp.com/api/job/#{job.id}/import"
    end

    it 'logs' do
      expect(stdout.string).to include "Merge#notify:completed Notifying merge to import job id=#{job.id}"
    end
  end
end
