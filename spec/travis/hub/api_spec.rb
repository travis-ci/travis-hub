require 'spec_helper'
require 'travis/hub/sidekiq/worker'

describe Travis::Hub::Api, :include_sinatra_helpers do
  let(:logs)    { Travis::Hub::Support::Logs }
  let(:job)     { FactoryGirl.create(:job, state: state) }
  let(:key)     { OpenSSL::PKey.read(Base64.decode64(JWT_RSA_PRIVATE_KEY)) }
  let(:token)   { JWT.encode(payload, key, 'RS512') }
  let(:auth)    { "Bearer #{token}" }
  let(:state)   { :started }
  let(:payload) { { sub: job.id.to_s } }

  before do
    logs.any_instance.stubs(:update)
    set_app described_class.new
    header 'Authorization', auth
    header 'Content-Type', 'application/json'
  end

  def patch(path, body)
    super(path, JSON.dump(body))
  end

  def post(path, body)
    super(path, JSON.dump(body))
  end

  shared_examples_for 'successfully updates the state' do |state|
    describe "given the state #{state}" do
      let(:event) { state }

      it 'returns status 200' do
        response = patch path, body
        expect(response.status).to eq 200
      end

      it 'sets the state to the job' do
        response = patch path, body
        expect(job.reload.state).to eq state
      end
    end
  end

  shared_examples_for 'responds with a cancelation' do |state|
    describe "given the state #{state}" do
      let(:event) { state }

      it 'returns status 409' do
        response = patch path, body
        expect(response.status).to eq 409
      end

      it 'does not change the job' do
        response = patch path, body
        expect(job.reload.state).to eq :canceled
      end
    end
  end

  describe 'PATCH /jobs/:job_id/state' do
    let(:path) { "/jobs/#{job.id}/state" }
    let(:body) { { new: event, received_at: Time.now } }

    describe 'with a queued job' do
      let(:state) { :queued }

      [:received, :created, :started, :passed, :failed, :errored].each do |state|
        include_examples 'successfully updates the state', state
      end
    end

    describe 'with a canceled job' do
      let(:state) { :canceled }

      [:received, :created, :started, :passed, :failed, :errored].each do |state|
        include_examples 'responds with a cancelation', state
      end
    end

    describe 'with a missing token' do
      let(:state) { :created }
      let(:event) { :received }
      let(:auth)  { nil }

      it 'returns status 401' do
        response = patch path, body
        expect(response.status).to eq 401
      end
    end

    describe 'with an invalid token' do
      let(:state) { :created }
      let(:event) { :received }
      let(:token) { 'invalid' }

      it 'returns status 403' do
        response = patch path, body
        expect(response.status).to eq 403
      end
    end
  end

  describe 'POST /jobs/:job_id/token' do
    let(:path) { "/jobs/#{id}/token" }
    let(:id)   { job.id }
    let(:resp) { post(path, {}) }
    let(:auth) { "Refresh #{token}" }
    let(:payload) { { sub: job.id, rand: '12345' } }
    let(:jwt_key) { "jwt-refresh:#{job.id}:12345" }

    before { context.redis.set(jwt_key, 1) }

    describe 'with a valid token' do
      it { expect(resp.status).to eq 200 }
    end

    describe 'with a missing token' do
      let(:auth) { nil }
      it { expect(resp.status).to eq 401 }
    end

    describe 'with an invalid token' do
      let(:token) { 'invalid' }
      it { expect(resp.status).to eq 403 }
    end

    describe 'with a different job_id' do
      let(:id) { 0 }
      it { expect(resp.status).to eq 403 }
    end

    describe 'with a missing jwt key in redis' do
      before { context.redis.del(jwt_key) }
      it { expect(resp.status).to eq 403 }
    end
  end

  describe 'POST /jobs/:job_id/events' do
    let(:path) { "/jobs/#{id}/events" }
    let(:body) { { event: 'deploy:finished', payload: { job_id: id, provider: :provider, state: :success }, datetime: Time.now } }
    let(:id)   { job.id }
    let(:auth) { "Access #{token}" }
    let(:resp) { post(path, body) }

    before { Sidekiq::Testing.inline! }
    after  { Sidekiq::Testing.disable! }

    describe 'with a valid token' do
      it { expect(resp.status).to eq 200 }
    end

    describe 'with a missing token' do
      let(:auth) { nil }
      it { expect(resp.status).to eq 401 }
    end

    describe 'with an invalid token' do
      let(:token) { 'invalid' }
      it { expect(resp.status).to eq 403 }
    end

    describe 'with a different job_id' do
      let(:id) { 0 }
      it { expect(resp.status).to eq 403 }
    end
  end
end
