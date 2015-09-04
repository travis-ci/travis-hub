describe Travis::Hub do
  let(:job)    { FactoryGirl.create(:job, state: :created) }
  let(:start)  { { event: 'start',  data: { id: job.id, started_at: Time.now } } }
  let(:finish) { { event: 'finish', data: { id: job.id, state: 'passed', finished_at: Time.now } } }

  def run(msg)
    Travis::Services::UpdateJob.new(msg).run
  end

  it 'works with unordered messages' do
    run(finish)
    run(start)
    expect(job.reload.state).to eql :passed
  end

  xit 'threaded' do
    10.times do
      threads = []
      build = FactoryGirl.create(:build, state: :created)

      jobs = [
        build.jobs.create(state: :created),
        build.jobs.create(state: :created),
        build.jobs.create(state: :created),
        # build.jobs.create(state: :created),
        # build.jobs.create(state: :created)
      ]
      msgs = jobs.map do |job|
        [
          { event: 'start',   data: { id: job.id, started_at: Time.now } },
          { event: 'receive', data: { id: job.id, received_at: Time.now } },
          { event: 'finish',  data: { id: job.id, state: 'passed', finished_at: Time.now } }
        ]
      end.flatten

      msgs.shuffle.each do |msg|
        threads << Thread.new {
          run(msg)
        }
      end

      sleep 1
      # threads.each(&:join)
      states = jobs.map { |job| job.reload.state }
      expect(states).to eql([:passed] * jobs.size)
    end
  end
end
