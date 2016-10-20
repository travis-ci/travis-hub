require 'spec_helper'

describe Travis::Hub::Api, :include_sinatra_helpers do
  let(:job)   { FactoryGirl.create(:job, state: state) }
  let(:key)   { OpenSSL::PKey.read(JWT_RSA_PRIVATE_KEY) }
  let(:token) { JWT.encode({ sub: job.id.to_s }, key, 'RS512') }
  let(:auth)  { "Bearer #{token}" }

  before do
    set_app described_class.new
    header 'Authorization', auth
    header 'Content-Type', 'application/json'
  end

  def patch(path, body)
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
end
