require 'spec_helper'

describe Travis::Hub::Handler::Job do
  let(:job)     { stub('job', :update_attributes => nil) }
  let(:payload) { Hashr.new }
  let(:handler) { Travis::Hub::Handler::Job.new(:event, Hashr.new(payload)) }

  before :each do
    handler.stubs(:job).returns(job)
  end

  describe '#handle' do
    it 'updates job attributes on job:test:started' do
      job.expects(:update_attributes).with(payload)
      handler.event = :'job:test:started'
      handler.handle
    end

    it 'appends the log on job:test:log' do
      ::Job::Test.expects(:append_log!)
      handler.event = :'job:test:log'
      handler.handle
    end
  end
end

