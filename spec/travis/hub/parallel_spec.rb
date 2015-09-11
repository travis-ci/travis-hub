describe Travis::Hub do
  let(:job)     { FactoryGirl.create(:job, state: :created) }
  let(:start)   { { event: 'start',   data: { id: job.id, started_at: Time.now } } }
  let(:receive) { { event: 'receive', data: { id: job.id, received_at: Time.now } } }
  let(:finish)  { { event: 'finish',  data: { id: job.id, state: 'passed', finished_at: Time.now } } }

  def run(msg)
    Travis::Hub::Services::UpdateJob.new(msg).run
  end

  it 'works with unordered messages (1)' do
    run(finish)
    run(receive)
    run(start)
    expect(job.reload.state).to eql :passed
  end

  it 'works with unordered messages (2)' do
    run(start)
    run(receive)
    run(finish)
    expect(job.reload.state).to eql :passed
  end
end
