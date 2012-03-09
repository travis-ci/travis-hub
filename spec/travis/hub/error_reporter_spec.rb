require 'spec_helper'

describe Travis::Hub::ErrorReporter do
  let(:reporter) { Travis::Hub::ErrorReporter.new }

  it "setup a queue" do
    reporter.queue.should be_instance_of(Queue)
  end

  it "should loop in a separate thread" do
    reporter.expects(:error_loop)
    reporter.run
    reporter.thread.join
  end
  
  it "should report an error when something is on the queue" do
    Hubble.expects(:report)
    reporter.queue.push(StandardError.new)
    reporter.pop
  end

  it "should not raise an error when pop fails" do
    reporter.queue.expects(:pop).raises(StandardError.new)
    expect {
      reporter.pop
    }.to_not raise_error
  end
end
