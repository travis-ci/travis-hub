require 'spec_helper'

describe Travis::Hub::Handler::Job do
  let(:payload)   { {} }
  let(:handler)   { Travis::Hub::Handler::Job.new(nil, payload) }
  let(:publisher) { stub('publisher', :publish => nil) }

  before :each do
    Travis::Features.start
  end

  describe '#handle' do
    it 'updates job attributes on job:test:started' do
      Travis.expects(:run_service).with(:update_job, data: payload)
      handler.event = 'job:test:started'
      handler.handle
    end

    it 're-routes the message to reporting.jobs.logs (:travis_logs enabled)' do
      Travis::Features.enable_for_all(:travis_logs)
      Travis::Amqp::Publisher.expects(:jobs).with('logs').returns(publisher)
      publisher.expects(:publish).with(:data => {}, :uuid => Travis.uuid)
      handler.event = 'job:test:log'
      handler.handle
    end

    it 'appends the log on job:test:log (:travis_logs disabled)' do
      Travis::Features.disable_for_all(:travis_logs)
      Travis.expects(:run_service).with(:logs_append, data: payload)
      handler.event = 'job:test:log'
      handler.handle
    end
  end
end

