describe Travis::Hub::Serialize::Keen::Job do
  let(:owner) { FactoryGirl.create(:user, login: 'login') }
  let(:times) { %i(created_at received_at started_at queued_at canceled_at finished_at).map { |attr| [attr, Time.now] }.to_h }
  let(:job)   { FactoryGirl.create(:job, times.merge(state: :passed, owner: owner)) }
  let(:repo)  { job.repository }
  let(:data)  { described_class.new(job).data[:jobs].first }

  before { Date.stubs(:today).returns(Date.parse('2016-10-14')) }

  it { expect(data[:id]).to                  eq job.id }
  it { expect(data[:repository_id]).to       eq repo.id }
  it { expect(data[:repository_slug]).to     eq repo.slug }
  it { expect(data[:repository_private]).to  eq repo.private }
  it { expect(data[:owner_type]).to          eq 'User' }
  it { expect(data[:owner_id]).to            eq owner.id }
  it { expect(data[:owner_login]).to         eq 'login' }
  it { expect(data[:created_at]).to          eq Time.now }
  it { expect(data[:received_at]).to         eq Time.now }
  it { expect(data[:started_at]).to          eq Time.now }
  it { expect(data[:queued_at]).to           eq Time.now }
  it { expect(data[:canceled_at]).to         eq Time.now }
  it { expect(data[:finished_at]).to         eq Time.now }
  it { expect(data[:duration]).to            eq job.duration }
  it { expect(data[:number]).to              eq job.number }
  it { expect(data[:state]).to               eq :passed }
  it { expect(data[:queue]).to               eq job.queue }
  it { expect(data[:account_info]).to        eq nil }
end
