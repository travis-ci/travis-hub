describe Travis::Addons::Serializer::Keen::Job do
  let(:owner) { FactoryGirl.create(:user, login: 'login') }
  let(:times) { %i(created_at queued_at received_at started_at finished_at).map.with_index { |attr, ix| [attr, Time.now + 60 * ix] }.to_h }
  let(:job)   { FactoryGirl.create(:job, times.merge(state: :passed, owner: owner, queue: 'gce')) }
  let(:repo)  { job.repository }
  let(:build) { job.build }
  let(:data)  { described_class.new(job).data[:jobs].first }

  xit { expect(data[:account_type]).to        eq 'trial' }

  it { expect(data[:repository][:id]).to      eq repo.id }
  it { expect(data[:repository][:slug]).to    eq repo.slug }
  it { expect(data[:repository][:private]).to eq false }

  it { expect(data[:owner][:type]).to         eq 'User' }
  it { expect(data[:owner][:id]).to           eq owner.id }
  it { expect(data[:owner][:login]).to        eq 'login' }

  it { expect(data[:build][:id]).to           eq job.build.id }
  it { expect(data[:build][:type]).to         eq 'push' }
  it { expect(data[:build][:number]).to       eq build.number }
  it { expect(data[:build][:branch]).to       eq 'master' }

  it { expect(data[:job][:id]).to             eq job.id }
  it { expect(data[:job][:number]).to         eq job.number }
  it { expect(data[:job][:state]).to          eq :passed }
  it { expect(data[:job][:queue]).to          eq 'gce' }
  it { expect(data[:job][:wait_time]).to      eq 60 }
  it { expect(data[:job][:queue_time]).to     eq 60 }
  it { expect(data[:job][:boot_time]).to      eq 60 }
  it { expect(data[:job][:run_time]).to       eq 60 }
end
