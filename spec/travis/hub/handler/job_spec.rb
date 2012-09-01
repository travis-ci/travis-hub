require 'spec_helper'

describe Travis::Hub::Handler::Job do
  let(:job)       { stub('job', :update_attributes => nil) }
  let(:payload)   { {} }
  let(:handler)   { Travis::Hub::Handler::Job.new(nil, payload) }
  let(:publisher) { stub('publisher', :publish => nil) }

  before :each do
    handler.stubs(:job).returns(job)
  end

  describe '#handle' do
    it 'updates job attributes on job:test:started' do
      job.expects(:update_attributes).with(payload)
      handler.event = 'job:test:started'
      handler.handle
    end

    it 're-routes the message to reporting.jobs.logs' do
      Travis::Amqp::Publisher.expects(:jobs).with('logs').returns(publisher)
      publisher.expects(:publish).with(:data => {}, :uuid => Travis.uuid)
      handler.event = 'job:test:log'
      handler.handle
    end
  end
end

