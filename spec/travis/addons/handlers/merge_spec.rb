describe Travis::Addons::Handlers::Merge do
  let(:repo)    { FactoryGirl.create(:repository, migration_status: 'migrated', migrated_at: Time.now) }
  let(:job)     { FactoryGirl.create(:job, state: :created, repository: repo) }
  let(:build)   { FactoryGirl.create(:build, state: :created, repository: repo) }
  let(:handler) { described_class.new('build:finished', id: build.id) }
  let(:cache)   { described_class.states_cache }

  before { Travis::Event.setup([:merge]) }
  before { ENV['MERGE_API_TOKEN'] = '1234' }
  before { stub_request(:any, /.*/) }

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
