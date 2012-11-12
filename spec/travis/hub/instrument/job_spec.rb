require 'spec_helper'
require 'json'

describe Travis::Hub::Instrument::Handler::Job do
  include Travis::Testing::Stubs

  let(:payload)   { { 'id' => 1, 'some' => 'payload' } }
  let(:publisher) { Travis::Notification::Publisher::Memory.new }
  let(:handler)   { Travis::Hub::Handler::Job.new(nil, payload) }
  let(:job)       { stub('job', :update_attributes => nil) }
  let(:event)     { publisher.events.last }

  before :each do
    Travis::Notification.publishers.replace([publisher])
    Job.stubs(:find).returns(job)
    Job::Test.stubs(:append_log!)
  end

  it 'publishes a payload on update' do
    handler.event = 'job:test:started'
    handler.handle

    event.should publish_instrumentation_event(
      :event => 'travis.hub.handler.job.update:completed',
      :message => 'Travis::Hub::Handler::Job#update:completed for #<Job id="1">',
    )
    event[:data].should == {
      :event => 'job:test:started',
      :payload => payload
    }
  end

  # disabled for now cuz it's too spammy
  # it 'publishes a payload on log' do
  #   handler.event = 'job:test:log'
  #   handler.handle

  #   event[:payload].should == {
  #     :msg => 'Travis::Hub::Handler::Job#log for #<Job id="1">',
  #     :event => 'job:test:log',
  #     :payload => payload
  #   }
  # end
end
