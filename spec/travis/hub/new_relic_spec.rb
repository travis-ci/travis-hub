require 'spec_helper'
require 'core_ext/module/include'

class InstrumentableMock
  include do
    attr_reader :handled

    def handle
      @handled = true
    end
  end

  extend Travis::Hub::NewRelic::Instrumentation
  add_transaction_tracer :handle, :category => :task
end

class NewRelicMock
  attr_reader :args

  def perform_action_with_newrelic_trace(*args)
    @args = args
    yield
  end
end

describe Travis::Hub::NewRelic do
  describe 'add_transaction_tracer' do
    let(:target) { InstrumentableMock }

    it 'includes a module that defines the given methods' do
      methods = target.included_modules.first.instance_methods(false)
      methods.should include(:handle)
    end
  end

  describe 'instrumentation' do
    let(:instrumentable) { InstrumentableMock.new }
    let(:new_relic)      { NewRelicMock.new }

    before :each do
      instrumentable.stubs(:new_relic).returns(new_relic)
    end

    it 'still calls the instrumented method' do
      instrumentable.handle
      instrumentable.handled.should be_true
    end

    it 'notifies new relic with the expected payload' do
      instrumentable.handle
      new_relic.args.should == [{ :name => :handle, :category => :task }]
    end
  end
end
