describe Travis::Addons::Handlers::Pusher do
  let(:user)    { FactoryGirl.create(:user) }
  let(:repo)    { FactoryGirl.create(:repository, owner: user) }
  let(:build)   { FactoryGirl.create(:build, repository: repo, config: { notifications: config }) }
  let(:job)     { FactoryGirl.create(:job, repository: repo) }
  let(:config)  { { pusher: 'room' } }

  describe 'subscription' do
    before { Travis::Event.setup([:pusher]) }

    it 'job:started notifies' do
      described_class.expects(:notify)
      Travis::Event.dispatch('job:started', id: job.id)
    end

    it 'job:finished notifies' do
      described_class.expects(:notify)
      Travis::Event.dispatch('job:finished', id: job.id)
    end

    it 'build:started notifies' do
      described_class.expects(:notify)
      Travis::Event.dispatch('build:started', id: build.id)
    end

    it 'build:finished notifies' do
      described_class.expects(:notify)
      Travis::Event.dispatch('build:finished', id: build.id)
    end
  end

  describe 'handle' do
    let(:handler) { described_class.new(event, id: send(event.split(':').first).id) }

    describe 'a job event' do
      let(:event) { 'job:finished' }
      before do
        user.permissions.create!(repository: repo)
      end

      it 'enqueues a task' do
        ::Sidekiq::Client.any_instance.expects(:push).with do |payload|
          expect(payload['queue']).to   eq('pusher-live')
          expect(payload['class']).to   eq('Travis::Async::Sidekiq::Worker')
          expect(payload['args'][3]).to be_a(Hash)
          expect(payload['args'][4]).to eq(event: event, user_ids: [user.id])
        end
        handler.handle
      end

      it 'sends user_ids along with the request' do
        repo = job.repository

        ::Sidekiq::Client.any_instance.expects(:push).with do |payload|
          expect(payload['queue']).to   eq('pusher-live')
          expect(payload['class']).to   eq('Travis::Async::Sidekiq::Worker')
          expect(payload['args'][3]).to be_a(Hash)
          expect(payload['args'][4]).to eq(event: event, user_ids: [user.id])
        end
        handler.handle
      end
    end

    describe 'a build event' do
      let(:event) { 'build:finished' }

      it 'enqueues a task' do
        ::Sidekiq::Client.any_instance.expects(:push).with do |payload|
          expect(payload['queue']).to   eq('pusher-live')
          expect(payload['class']).to   eq('Travis::Async::Sidekiq::Worker')
          expect(payload['args'][3]).to be_a(Hash)
          expect(payload['args'][4]).to eq(event: event, user_ids: [])
        end
        handler.handle
      end
    end
  end

  # describe 'targets' do
  #   let(:room)  { 'travis:apitoken@42' }
  #   let(:other) { 'evome:apitoken@44' }

  #   it 'returns an array of rooms when given a string' do
  #     config[:pusher] = room
  #     expect(handler.targets).to eql [room]
  #   end

  #   it 'returns an array of rooms when given an array' do
  #     config[:pusher] = [room]
  #     expect(handler.targets).to eql [room]
  #   end

  #   it 'returns an array of rooms when given a comma separated string' do
  #     config[:pusher] = "#{room}, #{other}"
  #     expect(handler.targets).to eql [room, other]
  #   end

  #   it 'returns an array of rooms given a string within a hash' do
  #     config[:pusher] = { rooms: room, on_success: 'change' }
  #     expect(handler.targets).to eql [room]
  #   end

  #   it 'returns an array of rooms given an array within a hash' do
  #     config[:pusher] = { rooms: [room], on_success: 'change' }
  #     expect(handler.targets).to eql [room]
  #   end

  #   it 'returns an array of rooms given a comma separated string within a hash' do
  #     config[:pusher] = { rooms: "#{room}, #{other}", on_success: 'change' }
  #     expect(handler.targets).to eql [room, other]
  #   end
  # end
end
