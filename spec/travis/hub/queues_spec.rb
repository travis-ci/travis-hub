describe Travis::Hub::Queue do
  let(:handler) { ->(*) {} }
  let(:queue)   { Travis::Hub::Queue.new('builds', &handler) }
  let(:payload) { '{ "foo": "bar", "uuid": "2d931510-d99f-494a-8c67-87feb05e1594" }' }
  let(:message) { stub('message', ack: nil, properties: stub('properties', type: 'job:finish')) }

  def receive
    queue.send(:receive, message, payload)
  end

  describe 'receive' do
    it 'sets the given uuid to the current thread' do
      receive
      Thread.current[:uuid].should == '2d931510-d99f-494a-8c67-87feb05e1594'
    end

    describe 'with no exception being raised' do
      it 'handles the event' do
        handler.expects(:call).with('job:finish', 'foo' => 'bar')
        receive
      end

      it 'acknowledges the message' do
        message.expects(:ack)
        receive
      end
    end

    describe 'with an exception being raised' do
      before :each do
        handler.expects(:call).raises(StandardError.new('message'))
        $stdout = StringIO.new
      end

      after :each do
        $stdout = STDOUT
      end

      it 'outputs the exception' do
        receive
        $stdout.string.should =~ /message/
      end

      it 'acknowledges the message' do
        message.expects(:ack)
        receive
      end

      it 'notifies the error reporter' do
        Travis::Exceptions::Reporter.expects(:enqueue).with do |exception|
          $stdout = STDOUT
          exception.should be_instance_of(Travis::Hub::Error)
          exception.message.should =~ /message/
        end
        receive
      end
    end
  end

  describe 'decode' do
    it 'decodes a json payload' do
      queue.send(:decode, '{ "id": 1 }')['id'].should == 1
    end
  end
end
