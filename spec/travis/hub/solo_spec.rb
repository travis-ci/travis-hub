describe Travis::Hub::Solo do
  let(:subject) { described_class.new('solo') }

  describe 'setup' do
    before do
      # XXX: I tend to want to test this without knowing the
      # implementation details, but also don't want to refactor at
      # this stage (ever?).  Hmm...
      Travis::Database.stubs(:connect)
      Travis::Metrics.stubs(:setup)
      Travis::Exceptions::Reporter.stubs(:start)
      Travis::Notification.stubs(:setup)
      Travis::Addons.stubs(:register)
      subject.stubs(:declare_exchanges_and_queues)
    end

    it 'does not explode' do
      subject.setup
    end
  end

  describe 'run' do
    before do
      subject.stubs(:subscribe_to_queue)
      subject.stubs(:enqueue_jobs)
    end

    it 'subscribes to the queue' do
      subject.expects(:subscribe_to_queue)
      subject.run
    end
  end
end
