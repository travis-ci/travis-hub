require 'spec_helper'

describe Travis::Hub::ErrorReporter do
  let(:reporter) { Travis::Hub::ErrorReporter.new }

  before :each do
    Travis::Hub::ErrorReporter.queue = Queue.new
    Hubble.config['backend_name'] = 'memory'
    Hubble.raise_errors = false
  end

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
    expect { reporter.pop }.to_not raise_error
  end

  it "should allow pushing an error on the queue" do
    error = StandardError.new
    Travis::Hub::ErrorReporter.enqueue(error)
    reporter.queue.pop.should == error
  end

  it "should add custom metadata to hubble" do
    exception = StandardError.new
    error = Travis::Hub::Error.new('configure', {"type" => "pull_request"}, exception)
    reporter.handle(error)
    reported = Hubble.backend.reports.first
    reported["payload"].should == {'type' => "pull_request"}.inspect
    reported["event"].should == 'configure'
  end
end
