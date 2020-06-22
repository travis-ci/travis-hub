describe Travis::Hub::Service::UpdateJob do
  let(:redis)       { Travis::Hub.context.redis }
  let(:amqp)        { Travis::Amqp.any_instance }
  let(:job)         { FactoryGirl.create(:job, state: state, queued_at: queued_at, received_at: received_at) }
  let(:queued_at)   { now - 20 }
  let(:received_at) { now - 10 }
  let(:now)         { Time.now.utc }

  subject     { described_class.new(context, event, data) }

  before do
    amqp.stubs(:fanout)
    stub_request(:delete, %r{https://job-board\.travis-ci\.com/jobs/\d+\?source=hub})
      .to_return(status: 204)
  end

  describe 'receive event' do
    let(:state) { :queued }
    let(:event) { :receive }
    let(:data)  { { id: job.id, received_at: now } }

    it 'updates the job' do
      subject.run
      expect(job.reload.state).to eql(:received)
    end

    it 'instruments #run' do
      subject.run
      expect(stdout.string).to include("Travis::Hub::Service::UpdateJob#run:completed event: receive for repo=travis-ci/travis-core id=#{job.id}")
    end

    describe 'with received_at < queued_at (Worker living in the past' do
      let(:queued_at) { now + 10 }

      it 'sets received_at to queued_at' do
        subject.run
        expect(job.reload.received_at).to eq queued_at
      end
    end

    describe 'when the job has been canceled meanwhile' do
      let(:state) { :canceled }

      it 'does not update the job state' do
        subject.run
        expect(job.reload.state).to eql(:canceled)
      end

      it 'broadcasts a cancel message' do
        amqp.expects(:fanout).with('worker.commands', type: 'cancel_job', job_id: job.id, source: 'hub')
        subject.run
      end
    end
  end

  describe 'start event' do
    let(:state) { :queued }
    let(:event) { :start }
    let(:data)  { { id: job.id, started_at: now } }

    it 'updates the job' do
      subject.run
      expect(job.reload.state).to eql(:started)
    end

    it 'instruments #run' do
      subject.run
      expect(stdout.string).to include("Travis::Hub::Service::UpdateJob#run:completed event: start for repo=travis-ci/travis-core id=#{job.id}")
    end

    describe 'when the job has been canceled meanwhile' do
      let(:state) { :canceled }

      it 'does not update the job state' do
        subject.run
        expect(job.reload.state).to eql(:canceled)
      end

      it 'broadcasts a cancel message' do
        amqp.expects(:fanout).with('worker.commands', type: 'cancel_job', job_id: job.id, source: 'hub')
        subject.run
      end
    end
  end

  describe 'finish event' do
    let(:state) { :queued }
    let(:event) { :finish }
    let(:data)  { { id: job.id, state: :passed, finished_at: Time.now } }

    it 'updates the job' do
      subject.run
      expect(job.reload.state).to eql(:passed)
    end

    it 'instruments #run' do
      subject.run
      expect(stdout.string).to include("Travis::Hub::Service::UpdateJob#run:completed event: finish for repo=travis-ci/travis-core id=#{job.id}")
    end

    describe 'when job has been cancelled' do
      let(:state) { :created }
      let(:event) { :cancel }
      let(:data)  { { id: job.id } }
      let(:now) { Time.now }
      it 'checks email' do
        subject.run
      end
    end

  end

# # Build
# [ id: 172433521, repository_id: 14719283, number: "12", started_at: "2020-06-22 06:43:49", finished_at: "2020-06-22 06:43:49", created_at: "2020-06-22 06:43:33", updated_at: "2020-06-22 06:43:49", commit_id: 365385606, request_id: 367572412, state: "canceled", duration: 0,  owner_id: 591138, owner_type: "Organization", event_type: "push", previous_state: "failed",  pull_request_title: nil, pull_request_number: nil, branch: "master", canceled_at: "2020-06-22 06:43:49", cached_matrix_ids: [352016388, 352016389, 352016390, 352016391, 352016392], received_at: "2020-06-22 06:43:48", private: false, pull_request_id: nil, branch_id: 720644360, tag_id: nil, sender_id: 113940, sender_type: "User", org_id: nil, com_id: nil, config_id: 11350071, restarted_at: nil,                   unique_number: 12 ]
# [ id: 517658,    repository_id: 115741,   number: "2",  started_at: "2020-06-19 14:51:22", finished_at: "2020-06-19 14:51:39", created_at: "2020-06-09 05:23:15", updated_at: "2020-06-19 14:51:39", commit_id: 238904,    request_id: 171655,    state: "canceled", duration: 17, owner_id: 124513, owner_type: "User",         event_type: "push", previous_state: "errored", pull_request_title: nil, pull_request_number: nil, branch: "master", canceled_at: "2020-06-19 14:51:39", cached_matrix_ids: [517659],                                                received_at: "2020-06-09 05:23:16", private: false, pull_request_id: nil, branch_id: 267961,    tag_id: nil, sender_id: 124951, sender_type: "User", org_id: nil, com_id: nil, config_id: 35666,    restarted_at: "2020-06-19 14:51:03", unique_number: 2, tag: nil]
#
#
#
# # Job
# [id: 352016388, repository_id: 14719283, commit_id: 365385606, source_id: 172433521, source_type: "Build", queue: "builds.gce", type: "Job::Test", state: "canceled", number: "12.1", worker: nil, started_at: nil,                   finished_at: "2020-06-22 06:43:46", created_at: "2020-06-22 06:43:33", updated_at: "2020-06-22 06:43:46", tags: nil, allow_failure: nil,   owner_id: 591138, owner_type: "Organization", result: nil, queued_at: "2020-06-22 06:43:33", canceled_at: "2020-06-22 06:43:46", received_at: "2020-06-22 06:43:33", debug_options: nil, private: false, stage_id: 25238866,     stage_number: "1.1", org_id: nil, com_id: nil, config_id: 25999954, restarted_at: nil]
# [id: 517659,    repository_id: 115741,   commit_id: 238904,    source_id: 517658,    source_type: "Build", queue: "builds.gce", type: "Job::Test", state: "canceled", number: "2.1",  worker: nil, started_at: "2020-06-19 14:51:22", finished_at: "2020-06-19 14:51:39", created_at: "2020-06-09 05:23:15", updated_at: "2020-06-19 14:51:39", tags: nil, allow_failure: false, owner_id: 124513, owner_type: "User",         result: nil, queued_at: "2020-06-19 14:51:03", canceled_at: "2020-06-19 14:51:39", received_at: "2020-06-19 14:51:04", debug_options: nil, private: false, stage_id: 12710,        stage_number: "1.1", org_id: nil, com_id: nil, config_id: 29124,    restarted_at: "2020-06-19 14:51:03", priority: nil, job_state_id: 14420805]
#
# [id: 345950651, repository_id: 14546540, commit_id: 358808928, source_id: 170274253, source_type: "Build", queue: "builds.gce", type: "Job::Test", state: "errored",  number: "2.1", worker: nil, started_at: "2020-06-22 07:05:35", finished_at: "2020-06-22 07:06:10", created_at: "2020-06-08 11:24:17", updated_at: "2020-06-22 07:06:10", tags: nil, allow_failure: nil,   owner_id: 3610043,owner_type: "User",         result: nil, queued_at: "2020-06-22 07:05:16", canceled_at: nil,                   received_at: "2020-06-22 07:05:16", debug_options: nil, private: false, stage_id: 24590152,     stage_number: "1.1", org_id: nil, com_id: nil, config_id: 25698549, restarted_at: "2020-06-22 07:05:16"]
# [id: 345950652, repository_id: 14546540, commit_id: 358808928, source_id: 170274253, source_type: "Build", queue: "builds.gce", type: "Job::Test", state: "canceled", number: "2.2", worker: nil, started_at: nil,                   finished_at: "2020-06-22 07:06:10", created_at: "2020-06-08 11:24:17", updated_at: "2020-06-22 07:06:10", tags: nil, allow_failure: nil,   owner_id: 3610043,owner_type: "User",         result: nil, queued_at: nil,                   canceled_at: nil,                   received_at: nil,                   debug_options: nil, private: false, stage_id: 24590153,     stage_number: "2.1", org_id: nil, com_id: nil, config_id: 25698550, restarted_at: "2020-06-22 07:05:16"]
#
# [id: 351998454, repository_id: 14814673, commit_id: 365361545, source_id: 172426589, source_type: "Build", queue: "builds.gce", type: "Job::Test", state: "canceled", number: "9.1", worker: nil, started_at: "2020-06-22 05:25:30", finished_at: "2020-06-22 05:30:07", created_at: "2020-06-22 05:21:19", updated_at: "2020-06-22 05:30:07", tags: nil, allow_failure: nil,   owner_id: 3677846,owner_type: "User",         result: nil, queued_at: "2020-06-22 05:25:13", canceled_at: "2020-06-22 05:30:07", received_at: "2020-06-22 05:25:13", debug_options: nil, private: false, stage_id: nil,          stage_number: nil,   org_id: nil, com_id: nil, config_id: 25994436, restarted_at: "2020-06-22 05:25:13"]


  describe 'cancel event' do
    let(:state) { :created }
    let(:event) { :cancel }
    let(:data)  { { id: job.id } }
    let(:now) { Time.now }

    it 'updates the job' do
      subject.run
      expect(job.reload.state).to eql(:canceled)
      expect(job.reload.canceled_at).to eql(now)
    end

    it 'notifies workers' do
      amqp.expects(:fanout).with('worker.commands', type: 'cancel_job', job_id: job.id, source: 'hub')
      subject.run
    end

    it 'instruments #run' do
      subject.run
      expect(stdout.string).to include("Travis::Hub::Service::UpdateJob#run:completed event: cancel for repo=travis-ci/travis-core id=#{job.id}")
    end
  end

  describe 'restart event' do
    let(:state) { :passed }
    let(:event) { :restart }
    let(:data)  { { id: job.id } }

    it 'resets the job' do
      Job.any_instance.expects(:clear_log)
      subject.run
      expect(job.reload.state).to eql(:created)
    end

    it 'instruments #run' do
      Job.any_instance.expects(:clear_log)
      subject.run
      expect(stdout.string).to include("Travis::Hub::Service::UpdateJob#run:completed event: restart for repo=travis-ci/travis-core id=#{job.id}")
    end
  end

  describe 'a :restart event with state: :created passed (legacy worker?)' do
    let(:state) { :started }
    let(:event) { :restart }
    let(:data)  { { id: job.id, state: :created } }

    it 'updates the job' do
      Job.any_instance.expects(:clear_log)
      subject.run
      expect(job.reload.state).to eql(:created)
    end
  end

  describe 'reset event' do
    let(:state) { :started }
    let(:event) { :reset }
    let(:data)  { { id: job.id } }

    it 'resets the job' do
      Job.any_instance.expects(:clear_log)
      subject.run
      expect(job.reload.state).to eql(:created)
    end

    it 'instruments #run' do
      Job.any_instance.expects(:clear_log)
      subject.run
      expect(stdout.string).to include("Travis::Hub::Service::UpdateJob#run:completed event: reset for repo=travis-ci/travis-core id=#{job.id}")
    end

    describe 'with resets being limited' do
      let(:url)     { 'http://logs.travis-ci.org/' }
      let(:started) { Time.now - 7 * 3600 }
      let(:limit)   { Travis::Hub::Limit.new(redis, :resets, job.id) }
      let(:state)   { :queued }

      before { context.config[:logs_api] = { url: url, token: '1234' } }
      before { stub_request(:put, "http://logs.travis-ci.org/logs/#{job.id}?source=hub") }
      before { 50.times { limit.record(started) } }

      describe 'sets the job to :errored' do
        before { subject.run }
        it { expect(job.reload.state).to eql(:errored) }
      end

      describe 'logs a message' do
        before { subject.run }
        it { expect(stdout.string).to include "Resets limited: 50 resets between 2010-12-31 15:02:00 UTC and #{Time.now.to_s} (max: 50, after: 21600)" }
      end
    end
  end

  describe 'unordered messages' do
    let(:job)     { FactoryGirl.create(:job, state: :created) }
    let(:start)   { [:start,   { id: job.id, started_at: Time.now }] }
    let(:receive) { [:receive, { id: job.id, received_at: Time.now }] }
    let(:finish)  { [:finish,  { id: job.id, state: 'passed', finished_at: Time.now }] }

    def recieve(msg)
      described_class.new(context, *msg).run
    end

    it 'works (1)' do
      recieve(finish)
      recieve(receive)
      recieve(start)
      expect(job.reload.state).to eql :passed
    end

    it 'works (2)' do
      recieve(start)
      recieve(receive)
      recieve(finish)
      expect(job.reload.state).to eql :passed
    end
  end
end
